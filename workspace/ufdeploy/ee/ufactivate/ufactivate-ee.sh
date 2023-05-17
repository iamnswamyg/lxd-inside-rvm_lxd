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

DEPLOY_ENV_PATH=${2:-ufenv-${APP_NAME}-${APP_CONF}-${TARGET_NAME}.sh}

RANDOM_KEY=$RANDOM

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ] || [ -z "$TARGET_NAME" ] || [ ! -z "$EMPTY"]; then
  quit $'ufactivate-ee.sh path/<app_name>-<app_conf>-<app_ver>-<target_name>[.dist.tar]\nufactivate-ee.sh /tmp/ufoee-test-201407070949-ee.tar'
fi

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
	which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

source $DEPLOY_ENV_PATH

log "TARGET_APP: $TARGET_APP"

# Start scripts on the targeted servers
log "Starting execution of remote scripts on ee-servers $TARGET_APP"
salt -L "${TARGET_APP}" --async cmd.run "ufactivate-ee-app.sh $RANDOM_KEY $TARGET_APP_PORT $APP_NAME $APP_CONF $APP_VER $TARGET_APP_WEB_PORT $TARGET_APP_SHUTDOWN_PORT"

log "use 'salt-run jobs.lookup_jid <JID>' for info"

# Wait for all servers to begin activation
log "Waiting for activation started"
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=10 --port=${TARGET_APP_PORT} ${TARGET_APP} || quit "START"
log "Activation started"

# Wait for ee servers to restart application
log "Waiting for STEP1..."
ufdeploy-coordinator --key "STEP1-DONE-${RANDOM_KEY}" --timeout=20 --port=${TARGET_APP_PORT} ${TARGET_APP} || quit "STEP1"
log "STEP1 done"

log "Waiting 10 seconds for restart..."
sleep 10

for TARGET in $TARGET_APP; do
	DONE=false
	while [[ "$DONE" != true ]]; do
		PING_COMMAND="wget -O- \"http://${TARGET}:${TARGET_APP_WEB_PORT}/APPLICATION_STATUS\""
		log "Pinging application on $TARGET: $PING_COMMAND"
		PING_RESULT=$(eval $PING_COMMAND 2>/tmp/ping.tmp.$$)
		if [ $? -ne 0 ]; then
	  	    # FAILED
		    PING_ERROR=`cat /tmp/ping.tmp.$$`
		    log "PING FAIL: $PING_RESULT"
		    log "PING ERROR: $PING_ERROR"
		    rm -f /tmp/ping.tmp.$$
		    quit "Unable to ping application $TARGET. Activate failed"
		else
		    rm -f /tmp/ping.tmp.$$
		    DONE=true 
		fi
		log "PING: $PING_RESULT"
	done
done

log "App $DIST_NAME activated"

log "Notifying Microsoft teams"
ufnotify-msteams.sh $0 $APP_NAME $DIST_NAME $LINKS
