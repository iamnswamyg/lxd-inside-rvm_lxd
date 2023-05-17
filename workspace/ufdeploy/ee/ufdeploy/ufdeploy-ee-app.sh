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

DEPLOY_PATH="/usr/local/${APP_NAME}"

log "SYNC_PORT: $SYNC_PORT"
log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"

LONG_NAME=${APP_NAME}-${APP_CONF}-${APP_VER}-${TARGET_NAME}
APP_CONTEXT=${APP_NAME}-${APP_CONF}-${APP_VER}

log "Deploying ${LONG_NAME}"

# Check if file exists
if [ ! -f "/tmp/${LONG_NAME}.dist.tar" ]; then
  log "Missing file /tmp/${LONG_NAME}.dist.tar"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Deploy failed"
fi

log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "START sync failed"

log "Extracting files"
tar -xf "/tmp/${LONG_NAME}.dist.tar" --directory "${DEPLOY_PATH}" || quit "Failed to extract files from /tmp/${LONG_NAME}.dist.tar"
log "Setting rights/permissions"
tar -tf "/tmp/${LONG_NAME}.dist.tar" | awk "{ print \"${DEPLOY_PATH}/\" \$1 }" | xargs chown unifaun:unifaun
{% if grains['osfinger'] == 'Ubuntu-14.04' %}
chown tomcat7:root ${DEPLOY_PATH}/data/tmp
{% endif %}
{% if grains['osfinger'] == 'Ubuntu-18.04' %}
chown tomcat8:root ${DEPLOY_PATH}/data/tmp
{% endif %}

chmod a+x ${DEPLOY_PATH}/${APP_CONTEXT}/bin/start-version.sh

log "Waiting for STEP1-DONE synch"
ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT} || quit "STEP1-DONE sync failed"
log "${LONG_NAME} DEPLOY DONE"

log "Cleanup"
rm /tmp/${LONG_NAME}.dist.tar
