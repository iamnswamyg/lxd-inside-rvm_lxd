#!/bin/bash
HOSTNAME=$(hostname)

function quit {
  echo "$HOSTNAME $(date) DEPLOY FAILED: $1"
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

{% if grains.id == 'ufoffice-tmpsalt' %}
TARGET_HOSTS="ufoffice-test1"
{% else %}
TARGET_HOSTS="{{ colo_site }}-app1-${TARGET_NAME} {{ colo_site }}-app2-${TARGET_NAME}"
{% endif %}
SYNC_PORT=8283

LONG_NAME=${APP_NAME}-${APP_CONF}-${APP_VER}-${TARGET_NAME}
APP_CONTEXT=${APP_NAME}-${APP_CONF}-${APP_VER}

if [ $APP_VER = "current" ]; then
  UPDATE="true"
else
  UPDATE="false"
fi

log "Deploying ${LONG_NAME} to tomcats ${TARGETS}"

# Check if file exists
if [ ! -f "/tmp/${LONG_NAME}.app.war" ]; then
  log "Missing file /tmp/${LONG_NAME}.app.war"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Deploy failed"
fi

log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "START sync failed"

for TARGET_HOST in ${TARGET_HOSTS}; do
  log "Deploying ${LONG_NAME} to ${TARGET_HOST} (update=${UPDATE})"
  curl --connect-timeout 5 -sS --upload-file /tmp/${LONG_NAME}.app.war "http://unifaun:pasta@${TARGET_HOST}:8080/manager/text/deploy?path=/${APP_CONTEXT}&update=${UPDATE}"
done

declare -A PING_URLS
declare -A PING_RESULTS

{% set webapps = pillar['ufconfig']['applications'] %}
{% for name in webapps %}{% set app = webapps[name] %}{% if 'ping' in app %}{% set ping = app['ping'] %}
PING_URLS["{{ name }}"]="{{ ping['url'] }}"
PING_RESULTS["{{ name }}"]="{{ ping['expected-response'] }}"
{% endif %}{% endfor %}

log "Checking webapp"
CHECK_FAILED=0
for TARGET_HOST in ${TARGET_HOSTS}; do
  PING_URL=http://${TARGET_HOST}:8080/${APP_CONTEXT}/${PING_URLS["${APP_NAME}"]}
  PING_COMMAND="wget -q -O- \"$PING_URL\""
  log "Pinging applicatin on $TARGET_HOST: $PING_COMMAND"
  PING_RESULT=$(eval $PING_COMMAND)
  EXPECTED_RESULT=${PING_RESULTS["${APP_NAME}"]}
  if [ $? -ne 0 ] || [ "$PING_RESULT" != "$EXPECTED_RESULT" ]; then
    # FAILED
    CHECK_FAILED=1
  fi
  log "PING: $PING_RESULT"
done

if [ $CHECK_FAILED -ne 0 ]; then
  log "One or more targets failed to respond to ping"
  ufdeploy-synchronizer --fail --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 120  --addr :${SYNC_PORT}
  quit "TOMCAT DEPLOY FAILED"
fi

ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 50  --addr :${SYNC_PORT} || quit "STEP1-DONE sync failed"
echo "TOMCAT DEPLOY DONE"

log "Cleanup"
rm /tmp/${LONG_NAME}.app.war

