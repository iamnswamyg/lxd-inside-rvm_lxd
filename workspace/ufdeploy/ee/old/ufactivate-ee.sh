#!/bin/bash

function quit {
  echo "$(date) ACTIVATE-APP FAILED: $1"
  exit 1
}

function log {
  echo "$(date) $1"
}

SRC_PATH=$1
DIST_NAME=$(basename -s ".dist.tar" $SRC_PATH)
TMP1=(${DIST_NAME//-/ })
APP_NAME=${TMP1[0]}
APP_CONF=${TMP1[1]}
APP_VER=${TMP1[2]}
TARGET_NAME=${TMP1[3]}
EMPTY=${TMP1[4]}

log "DIST_NAME: $DIST_NAME"
log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"

EE_SERVERS="ufcolo1-app1-${TARGET_NAME} ufcolo1-app2-${TARGET_NAME} ufcolo2-app1-${TARGET_NAME} ufcolo2-app2-${TARGET_NAME}"

SYNC_PORT=8283
RANDOM_KEY=$RANDOM

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ] || [ -z "$TARGET_NAME" ] || [ ! -z "$EMPTY"]; then
  quit $'ufactivate-ee.sh path/<app_name>-<app_conf>-<app_ver>-<target_name>[.dist.tar]\nufactivate-ee.sh /tmp/ufoee-test-201407070949-ee.tar'
fi

# Start scripts on the targeted servers
log "Starting execution of remote scripts on ee-servers $EE_SERVERS"
salt -L "${EE_SERVERS}" --async cmd.run "ufactivate-ee-app.sh $RANDOM_KEY $APP_NAME $APP_CONF $APP_VER"

log "use 'salt-run jobs.lookup_jid <JID>' for info"

# Wait for all servers to begin activation
log "Waiting for activation started"
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=10 --port=${SYNC_PORT} ${EE_SERVERS} || quit "START"
log "Activation started"

# Wait for ee servers to restart application
log "Waiting for STEP1..."
ufdeploy-coordinator --key "STEP1-DONE-${RANDOM_KEY}" --timeout=20 --port=${SYNC_PORT} ${EE_SERVERS} || quit "STEP1"
log "STEP1 done"

log "App $DIST_NAME activated"
