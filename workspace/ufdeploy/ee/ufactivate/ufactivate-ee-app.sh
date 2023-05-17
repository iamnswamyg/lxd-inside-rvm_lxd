#!/bin/bash
HOSTNAME=$(hostname)

function quit {
  echo "$HOSTNAME $(date) ACTIVATE-APP FAILED: $1"
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
WEB_PORT="$6"
SHUTDOWN_PORT="$7"

DEPLOY_PATH=/usr/local/$APP_NAME

log "SYNC_PORT: $SYNC_PORT"
log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "WEB_PORT: $WEB_PORT"
log "SHUTDOWN_PORT: $SHUTDOWN_PORT"

TARGET_HOST=localhost

APP_CONTEXT=${APP_NAME}-${APP_CONF}-${APP_VER}

log "Activating ${APP_CONTEXT}"

# Check if file exists
if [ ! -d "$DEPLOY_PATH/${APP_CONTEXT}" ]; then
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "File $SRC_PATH not found"
fi
log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "START sync failed"

log "Copying files for activation"
if [ ! -d "${DEPLOY_PATH}/bin" ]; then
  mkdir ${DEPLOY_PATH}/bin/
fi
cp ${DEPLOY_PATH}/${APP_CONTEXT}/bin/start.sh ${DEPLOY_PATH}/bin/start.sh
chmod a+x ${DEPLOY_PATH}/bin/start.sh
cp ${DEPLOY_PATH}/${APP_CONTEXT}/bin/stop.sh ${DEPLOY_PATH}/bin/stop.sh
chmod a+x ${DEPLOY_PATH}/bin/stop.sh

log "Restart $APP_NAME on $HOSTNAME"
log "$(echo shutdown | nc localhost ${SHUTDOWN_PORT})"

ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT} || quit "STEP1-DONE sync failed"
echo "EE ACTIVATION DONE"
