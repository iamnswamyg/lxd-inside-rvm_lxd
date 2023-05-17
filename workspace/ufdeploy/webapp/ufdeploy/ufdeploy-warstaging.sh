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
SYNC_PORT="$2"
APP_NAME="$3"
APP_CONF="$4"
APP_VER="$5"
TARGET_NAME="$6"
TARGET_HOSTS="$7"

HOSTNAME="$(hostname)"

log "RANDOM_KEY: $RANDOM_KEY"
log "SYNC_PORT: $SYNC_PORT"
log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"
log "TARGET_HOSTS: $TARGET_HOSTS"
log "HOSTNAME: $HOSTNAME"

LONG_NAME=${APP_NAME}-${APP_CONF}-${APP_VER}-${TARGET_NAME}
APP_CONTEXT=${APP_NAME}-${APP_CONF}-${APP_VER}

if [ -z "$TARGET_HOSTS" ]; then
  log "No target hosts"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Deploy failed"
fi

if [ $APP_VER = "current" ]; then
  UPDATE="true"
else
  UPDATE="false"
fi
{% raw %}
TARGETS=$(for TARGET_HOST in $TARGET_HOSTS; do if [[ $TARGET_HOST == "$HOSTNAME:"* ]]; then echo ${TARGET_HOST:${#HOSTNAME}+1}; fi; done)
{% endraw %}
log "Deploying ${LONG_NAME} to tomcats ${TARGETS}"

# Check if file exists
if [ ! -f "/tmp/${LONG_NAME}.app.war" ]; then
  log "Missing file /tmp/${LONG_NAME}.app.war"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Deploy failed"
fi

for TARGET in $TARGETS; do
	if ping -c 1 "$TARGET" &> /dev/null; then
		log "$TARGET reachable"
	else
		log "$TARGET unreachable"
		ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
		quit "Deploy failed"
	fi
done

log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "START sync failed"

for TARGET_HOST in ${TARGETS}; do
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
for TARGET_HOST in ${TARGETS}; do
  PING_URL=http://${TARGET_HOST}:8080/${APP_CONTEXT}/${PING_URLS["${APP_NAME}"]}
  PING_COMMAND="wget --read-timeout=10 -q -O- \"$PING_URL\""
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

