#!/bin/bash

function quit {
  echo "$(date) DEPLOY FAILED: $1"
  exit 1
}

function log {
  echo "$(date) $1"
}

function transfer {
  log "Transfereing $2 to to $1"
  salt "$1" --out txt cp.get_file "salt://ufdeploy/dist/${DIST_NAME}/$2" "/tmp/$2"
  if [ $? -ne 0 ]; then
    quit "Failed to transfere file"
  fi
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

SYNC_PORT=8283
DNS_SYNC_PORT=8284

DNS_SERVER="ufoffice-prod1"
DNS_SERVER_AND_PORT="${DNS_SERVER}:${DNS_SYNC_PORT}"
WAR_SERVERS="ufoffice-prod1"
WEB_SERVERS="ufoffice-test1"

RANDOM_KEY=$RANDOM
SALT_DIST_PATH="/srv/saltstack/salt/ufdeploy/dist"


if [[ ! "$SRC_PATH" == *.dist.tar ]]; then
  quit "Input file name must end with .dist.tar"
fi

if [ ! -f "$SRC_PATH" ]; then
  quit "File $SRC_PATH not found"
fi

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ] || [ -z "$TARGET_NAME" ] || [ ! -z "$EMPTY"]; then
  quit $'ufdeploy.sh path/<app_name>-<app_conf>-<app_ver>-<target_name>.tar\nufdeploy.sh /tmp/ufoweb-test-201407070949-ufo.tar'
fi

# Extract file to /srv
log "Extracting files from $SRC_PATH"
tar -xf "$SRC_PATH" --directory "$SALT_DIST_PATH" || exit "Failed to extract files from $SRC_PATH"


if [ ! -f "${SALT_DIST_PATH}/${DIST_NAME}/${DIST_NAME}.nsupdate.txt" ]; then
  DNS_SERVER=""
fi

if [ ! -f "${SALT_DIST_PATH}/${DIST_NAME}/${DIST_NAME}.app.war" ]; then
  quit "Missing file ${DIST_NAME}.app.war"
fi

if [ ! -f "${SALT_DIST_PATH}/${DIST_NAME}/${DIST_NAME}.web.tar.gz" ]; then
  WEB_SERVERS=""
fi

# Transfere files
log "Transfering files"
if [ ! -z "$DNS_SERVER" ]; then
  transfer "$DNS_SERVER" "${DIST_NAME}.nsupdate.txt"
fi

for WAR_SERVER in $WAR_SERVERS; do
  transfer "$WAR_SERVER" "${DIST_NAME}.app.war"
done

for WEB_SERVER in $WEB_SERVERS; do
  transfer "$WEB_SERVER" "${DIST_NAME}.web.tar.gz"
done

# Deleteing files
log "Deleting files source"
rm -r "${SALT_DIST_PATH}/${DIST_NAME}"

# Start scripts on the targeted servers
if [ ! -z "$DNS_SERVER" ]; then
  log "Starting execution of remote script on dns-server $DNS_SERVER"
  salt -L "${DNS_SERVER}" --async cmd.run "ufdeploy-dns.sh $RANDOM_KEY $APP_NAME $APP_CONF $APP_VER $TARGET_NAME"
fi

log "Starting execution of remote scripts on war-deploy-servers $WAR_SERVERS"
salt -L "${WAR_SERVERS}" --async cmd.run "ufdeploy-tomcat.sh $RANDOM_KEY $APP_NAME $APP_CONF $APP_VER $TARGET_NAME"

if [ ! -z "$WEB_SERVERS" ]; then
 log "Starting execution of remote scripts on web-servers $WEB_SERVERS"
 salt -L "${WEB_SERVERS}" --async cmd.run "ufdeploy-apache.sh $RANDOM_KEY $APP_NAME $APP_CONF $APP_VER $TARGET_NAME"
fi

log "use 'salt-run jobs.lookup_jid <JID>' for info"

# Wait for all servers to begin deploy
log "Waiting for deploy started"
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=10 --port=${SYNC_PORT} ${WAR_SERVERS} ${WEB_SERVERS} ${DNS_SERVER_AND_PORT} || quit "START"
log "Deploy started"

# Wait for war-servers to deploy app, web-servers to copy files and dns server to add names
log "Waiting for STEP1..."
ufdeploy-coordinator --key "STEP1-DONE-${RANDOM_KEY}" --timeout=120 --port=${SYNC_PORT} ${WAR_SERVERS} ${WEB_SERVERS} ${DNS_SERVER_AND_PORT} || quit "STEP1"
log "STEP1 done"

if [ ! -z "$WEB_SERVERS" ]; then
 # Wait for war-servers to deploy configuration and reload
 log "Waiting for STEP2..."
 ufdeploy-coordinator --key "STEP2-DONE-${RANDOM_KEY}" --timeout=40 --port=${SYNC_PORT} ${WEB_SERVERS} || quit "STEP2"
 log "STEP2 done"
fi

declare -A WARMUP_URLS
{% set webapps = pillar['ufconfig']['applications'] %}
{% for name in webapps %}{% set app = webapps[name] %}{% if 'warmup' in app %}{% set warmup = app['warmup'] %}
WARMUP_URLS["{{ name }}"]="{{ warmup['url'] }}"
{% endif %}{% endfor %}

TARGET_HOSTS="ufoffice-test1"

for TARGET_HOST in ${TARGET_HOSTS}; do
  WARMUP_URL=${WARMUP_URLS["${APP_NAME}"]}
  if [[ -n "$WARMUP_URL" ]]; then
    log "Calling warmup: ${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$WARMUP_URL"
    wget -q -O- "${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$WARMUP_URL"
  fi
done

log "App $DIST_NAME deployed"
