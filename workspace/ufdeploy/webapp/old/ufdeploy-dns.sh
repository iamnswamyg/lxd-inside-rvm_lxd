#!/bin/bash

function quit {
  echo "$HOSTNAME $(date) SWITCHOVER FAILED: $1"
  exit 1
}

function log {
  echo "$HOSTNAME $(date) $1"
}

RANDOM_KEY="$1"
APP_NAME="$2"
APP_CONF="$3"
APP_VER="$4"
TARGET_NAME="$5"

log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"

LONG_NAME=${APP_NAME}-${APP_CONF}-${APP_VER}-${TARGET_NAME}
SYNC_PORT=8284

echo "Deploying ${LONG_NAME} to dns $(hostname)"

# Check if file exists
if [ ! -f "/tmp/${LONG_NAME}.nsupdate.txt" ]; then
  log "Missing file /tmp/${LONG_NAME}.nsupdate.txt"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Deploy failed"

fi

log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 50  --addr :${SYNC_PORT} || quit "START sync failed"

echo "Updating DNS"
nsupdate "/tmp/${LONG_NAME}.nsupdate.txt"

log "Waiting for START synch"
ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 120  --addr :${SYNC_PORT} || quit "START sync failed"

echo "Cleanup"
rm /tmp/${LONG_NAME}.nsupdate.txt

