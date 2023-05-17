#!/bin/bash
# Is used of tomcat webapps and ufoee/hitee
HOSTNAME=$(hostname)

RANDOM_KEY=$1
SYNC_PORT=$2
WEB_PORT=$3
DB_PRI_GROUPS=$4
DB_SEC_GROUPS=$5

WEBAPP_NAME=switchover

function quit() {
  echo "$HOSTNAME $(date) SWITCHOVER FAILED: $1"
  exit 1
}

function recover() {
  echo "$HOSTNAME $(date) Recover switchover for ${DB_PRI_GROUPS}:${DB_SEC_GROUPS}"
  RECOVER=$(curl -s "http://localhost:${WEB_PORT}/${WEBAPP_NAME}/recover?groups=${DB_PRI_GROUPS}:${DB_SEC_GROUPS}")
  if [[ $RECOVER != "DONE" ]]; then
    echo "$HOSTNAME $(date) WARNING: Switchover recover for ${DB_PRI_GROUPS}:${DB_SEC_GROUPS} failed:"
    echo "$RECOVER"
    return 1
  fi
  echo "$HOSTNAME $(date) WARNING: Switchover recover done"
  return 0
}

# Wait for all servers to begin switchover
echo "$HOSTNAME $(date) Waiting for all servers"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 20 --wait 20  --addr :${SYNC_PORT} || quit "START sync failed"
echo "$HOSTNAME $(date) Switchover started"

# Preparing switchover
echo "$HOSTNAME $(date) Preparing switchover on ${HOSTNAME} for ${DB_PRI_GROUPS}"
PREPARE=$(curl -s "http://localhost:${WEB_PORT}/${WEBAPP_NAME}/prepare?groups=${DB_PRI_GROUPS}")
if [[ $PREPARE != "DONE" ]]; then
  ufdeploy-synchronizer --fail --key "APP-PREPARE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
  quit "Failed to prepare switchover for ${DB_PRI_GROUPS}: $PREPARE"
fi
echo "$HOSTNAME $(date) Waiting 5 seconds to give active connections a chanse to finnish"
sleep 5
if [ ! -z "${DB_SEC_GROUPS}" ]; then
  echo "$HOSTNAME $(date) Preparing switchover on ${HOSTNAME} for ${DB_SEC_GROUPS}"
  PREPARE=$(curl -s "http://localhost:${WEB_PORT}/${WEBAPP_NAME}/prepare?groups=${DB_SEC_GROUPS}")
  if [[ $PREPARE != "DONE" ]]; then
    ufdeploy-synchronizer --fail --key "APP-PREPARE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
    quit "Failed to prepare switchover for ${DB_SEC_GROUPS}: $PREPARE"
  fi
fi

echo "$HOSTNAME $(date) Prepare done"

# Waiting for APP-PREPARE-DONE
echo "$HOSTNAME $(date) Waiting for APP-PREPARE-DONE synch"
ufdeploy-synchronizer --key "APP-PREPARE-DONE-${RANDOM_KEY}" --accept 5 --wait 25  --addr :${SYNC_PORT}
if [ $? -ne 0 ]; then
  recover
  quit "APP-PREPARE-DONE sync failed"
fi

# Waiting for DB-DEMOTE-DONE
echo "$HOSTNAME $(date) Waiting for DB-DEMOTE-DONE synch"
ufdeploy-synchronizer --key "DB-DEMOTE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
if [ $? -ne 0 ]; then
  recover
  quit "DB-DEMOTE-DONE sync failed"
fi

# Waiting for DB-PROMOTE-DONE"
echo "$HOSTNAME $(date) Waiting for DB-PROMOTE-DONE synch"
ufdeploy-synchronizer --key "DB-PROMOTE-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
if [ $? -ne 0 ]; then
  recover
  quit "DB-PROMOTE-DONE sync failed"
fi

# Recovering
recover
if [ $? -ne 0 ]; then
  ufdeploy-synchronizer --fail --key "APP-RECOVER-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}
  quit "Recover failed"
fi

# Waiting for APP-RECOVER-DONE
ufdeploy-synchronizer --key "APP-RECOVER-DONE-${RANDOM_KEY}" --accept 5 --wait 20  --addr :${SYNC_PORT}

