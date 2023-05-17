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
TARGET_NAME="$6"

log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"

LONG_NAME=${APP_NAME}-${APP_CONF}-${APP_VER}-${TARGET_NAME}

log "Activating ${LONG_NAME} to apache"

# Cehck if file exists
if [ ! -d "/etc/apache2/sites-available/${LONG_NAME}" ]; then
  log "Missing directory /etc/apache2/sites-available/${LONG_NAME}"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Activate START failed"
fi

log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "START sync failed"

log "Copy configuration"
cp /etc/apache2/sites-available/${LONG_NAME}/* /etc/apache2/sites-available/

SITES=$(ls /etc/apache2/sites-available/${LONG_NAME}/ | grep "^.*\.conf$" | sed "s/\.conf//g")
for SITE in $SITES; do
  if [ ! -f "/etc/apache2/sites-enabled/${SITE}.conf" ]; then
    log "Enable site ${SITE}"
    a2ensite "$SITE"
  fi
done

log "Waiting for STEP1-DONE synch"
ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT} || quit "STEP1-DONE sync failed"

log "Reload apache configuration"
service apache2 reload
if  [ $? -ne 0 ]; then
  log "Failed to reload config"
  ufdeploy-synchronizer --fail --key "STEP2-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT}
  quit "Deploy STEP2-DONE failed"
fi

ufdeploy-synchronizer --key "STEP2-DONE-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "STEP2-DONE sync failed"
