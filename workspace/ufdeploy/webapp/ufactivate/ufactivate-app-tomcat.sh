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

log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"

TARGET_HOST=localhost

APP_CONTEXT=${APP_NAME}-${APP_CONF}-${APP_VER}

log "Activating ${APP_CONTEXT}"

# Check if file exists
CHECK_COMMAND="wget -q -O- \"http://${TARGET_HOST}:8080/fwdmanager/check?group=${APP_NAME}-${APP_CONF}&name=${APP_NAME}-${APP_CONF}-${APP_VER}\""
log "Check command: $CHECK_COMMAND"
CHECK_RESULT=$(eval $CHECK_COMMAND)
if [ $? -ne 0 ] || [ $CHECK_RESULT != "DONE" ]; then
  # FAILED
  log "CHECK: $CHECK_RESULT"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Check failed"
fi
log "CHECK: $CHECK_RESULT"
log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "START sync failed"

ACTIVATE_COMMAND="wget -q -O- \"http://${TARGET_HOST}:8080/fwdmanager/activate?group=${APP_NAME}-${APP_CONF}&name=${APP_NAME}-${APP_CONF}-${APP_VER}\""
log "Check command: $ACTIVATE_COMMAND"
ACTIVATE_RESULT=$(eval $ACTIVATE_COMMAND)
if [ $? -ne 0 ] || [ $ACTIVATE_RESULT != "DONE" ]; then
  # FAILED
  log "ACTIVATE: $ACTIVATE_RESULT"
  ufdeploy-synchronizer --fail --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT}
  quit "Activate failed"
fi
log "ACTIVATE: $ACTIVATE_RESULT"

declare -A PING_URLS
declare -A PING_RESULTS

{% set webapps = pillar['ufconfig']['applications'] %}
{% for name in webapps | sort %}{% set app = webapps[name] %}{% if 'ping' in app %}{% set ping = app['ping'] %}
PING_URLS["{{ name }}"]="{{ ping['url'] }}"
PING_RESULTS["{{ name }}"]="{{ ping['expected-response'] }}"
{% endif %}{% endfor %}

PING_URL=http://${TARGET_HOST}:8080/${APP_NAME}-${APP_CONF}-forwarder/${PING_URLS["${APP_NAME}"]}
EXPECTED_RESULT=${PING_RESULTS["${APP_NAME}"]}

PING_COMMAND="wget -q -O- \"${PING_URL}\""
log "Pinging applicatin on $TARGET_HOST: $PING_COMMAND"
PING_RESULT=$(eval $PING_COMMAND)
if [ $? -ne 0 ] || [ $PING_RESULT != "$EXPECTED_RESULT" ]; then
  # FAILED
  log "PING: $PING_RESULT"
  ufdeploy-synchronizer --fail --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT}
  quit "Activate failed"
fi
log "PING: $PING_RESULT"

ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT} || quit "STEP1-DONE sync failed"
echo "TOMCAT ACTIVATION DONE"
