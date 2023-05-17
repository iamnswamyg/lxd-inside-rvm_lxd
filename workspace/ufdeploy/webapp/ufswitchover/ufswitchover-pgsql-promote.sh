#!/bin/bash
function quit() {
  echo "$HOSTNAME $(date) SWITCHOVER PROMOTE FAILED: $1"
  exit 1
}

HOSTNAME=$(hostname)
RANDOM_KEY=$1
SYNC_PORT=$2

VERSION=$3
NAME=$4
MODE=$5

if [[ "$MODE" != "STD" ]] && [[ "$MODE" != "FORCE" ]]; then
	quit "Invalid mode: $MODE"
fi

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
if [[ $IS_IN_RECOVERY != "t" ]]; then
  echo "$HOSTNAME $(date) pg_is_in_recovery() expected to return 't' old slave: $IS_IN_RECOVERY"
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

# Waiting for DB-DEMOTE-DONE
echo "$HOSTNAME $(date) Waiting for DB-DEMOTE-DONE synch"
ufdeploy-synchronizer --key "DB-DEMOTE-DONE-${RANDOM_KEY}" --accept 5 --wait 25  --addr :${SYNC_PORT} || quit "DB-DEMOTE-DONE sync failed"

# Promoting old slave
if [[ "$MODE" == "FORCE" ]]; then
	REPLAY_LOCATION_DIFF="0"
else
	# Check that old slave have catched up to old master
	REPLAY_LOCATION_DIFF=$(sudo -iu postgres psql -p ${CLUSTER_PORT} postgres -Atc "SELECT pg_xlog_location_diff(pg_last_xlog_replay_location(), replay_location) from pg_stat_replication where application_name='s2s-replication'")
	echo "$HOSTNAME $(date) Replay location diff: $REPLAY_LOCATION_DIFF"
fi

if [[ $REPLAY_LOCATION_DIFF = "0" ]]; then
  echo "$HOSTNAME $(date) Old slave is ready for promotion"
  pg_ctlcluster ${CLUSTER_VERSION} ${CLUSTER_NAME} promote

  if [ $? -ne 0 ]; then
    echo "$HOSTNAME $(date) Failed to promote new master, old master should detect this and be repromoted, replay location diff: ${REPLAY_LOCATION_DIFF}"
  else
    echo $HOSTNAME "$(date) Promoted"
  fi

  for COUNT in {1..15}; do
    echo "$HOSTNAME $(date) Wating for cluster to stop recovery"
    IS_IN_RECOVERY=$(sudo -iu postgres psql -p ${CLUSTER_PORT} postgres -Atc "SELECT pg_is_in_recovery()")
    echo "$HOSTNAME $(date)  pg_is_in_recovery: $IS_IN_RECOVERY"
    if [[ $IS_IN_RECOVERY == "f" ]]; then
      break
    fi
    sleep 1
  done

else
  echo "$HOSTNAME $(date) Old slave not promoted as it has not catched up to old master, old master should detect this and be repromoted"
fi

# Waiting for DB-PROMOTE-DONE"
echo "$HOSTNAME $(date) Waiting for DB-PROMOTE-DONE synch"
ufdeploy-synchronizer --key "DB-PROMOTE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
if [ $? -ne 0 ]; then
  echo "$HOSTNAME $(date) Some cluster failed to promote"
fi
echo "$HOSTNAME $(date) DB-PROMOTE-DONE sync done"
