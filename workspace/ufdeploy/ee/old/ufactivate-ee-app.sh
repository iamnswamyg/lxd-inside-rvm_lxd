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
APP_NAME="$2"
APP_CONF="$3"
APP_VER="$4"

DEPLOY_PATH=/usr/local/$APP_NAME

log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"

TARGET_HOST=localhost
SYNC_PORT=8283

if [[ ${APP_NAME} = "ufoee" ]]; then
  PING_PORT="8182"
  SHUTDOWN_PORT="8172"
elif [[ ${APP_NAME} = "hitee" ]]; then
  PING_PORT="8183"
  SHUTDOWN_PORT="8171"
else
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Unknown app: ${APP_NAME}"
fi

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

log "Restart $APP_NAME on $HOSTNAME"
log "$(echo shutdown | nc localhost ${SHUTDOWN_PORT})"
log "Waiting 10 seconds..."
sleep 10

PING_COMMAND="wget -q -O- \"http://${TARGET_HOST}:${PING_PORT}/APPLICATION_STATUS\""
log "Pinging applicatin on $TARGET_HOST: $PING_COMMAND"
PING_RESULT=$(eval $PING_COMMAND)
if [ $? -ne 0 ]; then
  # FAILED
  log "PING: $PING_RESULT"
  ufdeploy-synchronizer --fail --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT}
  quit "Activate failed"
fi
log "PING: $PING_RESULT"

ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT} || quit "STEP1-DONE sync failed"
echo "EE ACTIVATION DONE"
