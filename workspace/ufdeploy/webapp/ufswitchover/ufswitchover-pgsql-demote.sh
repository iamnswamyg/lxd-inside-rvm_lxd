#!/bin/bash
function quit() {
  echo "$HOSTNAME $(date) SWITCHOVER DEMOTE FAILED: $1"
  exit 1
}

HOSTNAME=$(hostname)
SYNC_PORT=8283

RANDOM_KEY=$1
SYNC_PORT=$2
VERSION=$3
NAME=$4
CATCHUP_COUNT=$5

TMP=($(pg_lsclusters -h | grep $NAME | grep $VERSION))

CLUSTER_VERSION=${TMP[0]}
CLUSTER_NAME=${TMP[1]}
CLUSTER_PORT=${TMP[2]}
CLUSTER_DIR=${TMP[5]}

if [[ "$CLUSTER_NAME" != "$NAME" ]] || [[ "$CLUSTER_VERSION" != "$VERSION" ]]; then
	ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
	quit "Cluster $VERSION $NAME not found"
fi

echo CLUSTER_NAME: $CLUSTER_NAME
echo CLUSTER_VERSION: $CLUSTER_VERSION
echo CLUSTER_PORT: $CLUSTER_PORT
echo CLUSTER_DIR: $CLUSTER_DIR


IS_IN_RECOVERY=$(sudo -iu postgres psql -p ${CLUSTER_PORT} postgres -Atc "SELECT pg_is_in_recovery()")
if [[ $IS_IN_RECOVERY != "f" ]]; then
	echo "$HOSTNAME $(date) pg_is_in_recovery() expected to return 'f' on old master: $IS_IN_RECOVERY"
	echo "$HOSTNAME $(date) Aborting"
	ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
	quit "START failed"
fi

# Wait for all servers to begin switchover
echo "$HOSTNAME $(date) Waiting for all servers"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 20 --wait 20  --addr :${SYNC_PORT} || quit "START sync failed"
echo "$HOSTNAME $(date) Switchover started"

# Waiting for APP-PREPARE-DONE
echo "$HOSTNAME $(date) Waiting for APP-PREPARE-DONE synch"
ufdeploy-synchronizer --key "APP-PREPARE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT} || quit "APP-PREPARE-DONE sync failed"
echo "$HOSTNAME $(date) APP-PREPARE-DONE sync"

# Demoting
IS_IN_RECOVERY=$(sudo -iu postgres psql -p ${CLUSTER_PORT} postgres -Atc "SELECT pg_is_in_recovery()")
if [ $IS_IN_RECOVERY = "f" ]; then
	echo "$HOSTNAME $(date) Make cluster ${CLUSTER_NAME} go into recovery mode"
	echo "$HOSTNAME $(date) Copy ${CLUSTER_DIR}/recovery.template to ${CLUSTER_DIR}/recovery.conf"
	cp -p ${CLUSTER_DIR}/recovery.template ${CLUSTER_DIR}/recovery.conf || quit "Failed to copy ${CLUSTER_DIR}/recovery.template to ${CLUSTER_DIR}/recovery.conf"
	echo "$HOSTNAME $(date) Restarting cluster ${CLUSTER_NAME}"
	pg_ctlcluster -m fast ${CLUSTER_VERSION} ${CLUSTER_NAME} restart || quit "Failed to restart cluster ${CLUSTER_NAME}"
	echo "$HOSTNAME $(date) Restarted"
else
  echo "$HOSTNAME $(date) Cluster ${CLUSTER_NAME} already in recovery mode"
fi

echo "$HOSTNAME $(date) Query pg_is_in_recovery()"
IS_IN_RECOVERY=$(sudo -iu postgres psql -p ${CLUSTER_PORT} postgres -Atc "SELECT pg_is_in_recovery()")
if [ $IS_IN_RECOVERY = "t" ]; then
	echo "$HOSTNAME $(date) Cluster is in recovery mode"
else
  echo "$HOSTNAME $(date) Cluster is not in recovery mode! $IS_IN_RECOVERY"
  echo "Removing ${CLUSTER_DIR}/recovery.conf"
  rm ${CLUSTER_DIR}/recovery.conf
  ufdeploy-synchronizer --fail --key "DB-DEMOTE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
  quit "DEMOTE failed"
fi

# Wait for old slave to catch up
COUNTER=0
for (( COUNTER=0; ; COUNTER++ )); do
	REPLAY_LOCATION_DIFF=$(sudo -iu postgres psql -p ${CLUSTER_PORT} postgres -Atc "SELECT pg_xlog_location_diff(pg_last_xlog_replay_location(), replay_location) from pg_stat_replication where application_name='s2s-replication'")
	echo "$HOSTNAME $(date) Diff: $REPLAY_LOCATION_DIFF"
	if [[ $REPLAY_LOCATION_DIFF = "0" ]]; then
    	echo "$HOSTNAME $(date) Old slave should be ready for promot"
    	break
	elif [ $COUNTER -gt "$CATCHUP_COUNT" ]; then
    	echo "$HOSTNAME $(date) Old slave failed to catch up, repromoting old master"
    	pg_ctlcluster ${CLUSTER_VERSION} ${CLUSTER_NAME} promote
    	ufdeploy-synchronizer --fail --key "DB-DEMOTE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
    	quit "Old slave failed to catch up, old master repromoted"
	fi
	sleep 1
done

# Waiting for DB-DEMOTE-DONE
echo "$HOSTNAME $(date) Waiting for DB-DEMOTE-DONE synch"
ufdeploy-synchronizer --key "DB-DEMOTE-DONE-${RANDOM_KEY}" --accept 5 --wait 25  --addr :${SYNC_PORT}
if [ $? -ne 0 ]; then
	echo "$HOSTNAME $(date) Some cluster failed to demote, repromoting old master"
	pg_ctlcluster ${CLUSTER_VERSION} ${CLUSTER_NAME} promote || quit "DB-DEMOTE-DONE sync failed, failed to repromote old master"
	quit "DB-DEMOTE-DONE sync failed, old master repromoted"
fi

# Waiting for DB-PROMOTE-DONE"
# Ignore is ufdeploy was successfull or not, if old slave is still replicating if must have failed to promote and we should repromote this cluster
echo "$HOSTNAME $(date) Waiting for DB-PROMOTE-DONE synch"
ufdeploy-synchronizer --key "DB-PROMOTE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
if [ $? -ne 0 ]; then
	echo "$HOSTNAME $(date) Some cluster failed to promote"
fi

# Check if we should repromote this cluster (if other cluster still is replicating from this cluster)
REPROMOTE=$(sudo -iu postgres psql -p ${CLUSTER_PORT} postgres -Atc "SELECT true from pg_stat_replication where application_name='s2s-replication'")
if [[ $REPROMOTE = "t" ]]; then
  echo "HOSTNAME $(date) Old slave is still replicating from old master, repromoting old master"
  pg_ctlcluster ${CLUSTER_VERSION} ${CLUSTER_NAME} promote
  if [ $? -ne 0 ]; then
    quit "Failed to repromote old master, possibly no master left"
  else
    quit "Old master repromoted"
  fi
fi


echo "HOSTNAME $(date) Cluster demoted"
