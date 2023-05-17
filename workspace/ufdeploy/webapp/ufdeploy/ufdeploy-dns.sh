#!/bin/bash

function quit {
  echo "$HOSTNAME $(date) SWITCHOVER FAILED: $1"
  exit 1
}

function log {
  echo "$HOSTNAME $(date) $1"
}

RANDOM_KEY="$1"
SYNC_PORT="$2"
APP_NAME="$3"
APP_CONF="$4"
APP_VER="$5"
TARGET_NAME="$6"

log "RANDOM_KEY: $RANDOM_KEY"
log "SYNC_PORT: $SYNC_PORT"
log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"

LONG_NAME=${APP_NAME}-${APP_CONF}-${APP_VER}-${TARGET_NAME}

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
nsupdate -k /etc/bind/nsupdate-internal.bind.key "/tmp/${LONG_NAME}.nsupdate.txt"

log "Waiting for START synch"
ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 120  --addr :${SYNC_PORT} || quit "START sync failed"

echo "Cleanup"
rm /tmp/${LONG_NAME}.nsupdate.txt

