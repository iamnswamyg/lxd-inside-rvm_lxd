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

DEPLOY_ENV_PATH=${2:-ufenv-${APP_NAME}-${APP_CONF}-${TARGET_NAME}.sh}

log "DIST_NAME: $DIST_NAME"
log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"

RANDOM_KEY=$RANDOM

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ] || [ -z "$TARGET_NAME" ] || [ ! -z "$EMPTY"]; then
  quit $'ufactivate-app.sh path/<app_name>-<app_conf>-<app_ver>-<target_name>[.dist.tar]\nufdeploy.sh /tmp/ufoweb-test-201407070949-ufo.tar'
fi

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
	which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

source $DEPLOY_ENV_PATH

log "TARGET_APP_PORT: $TARGET_APP_PORT"
log "TARGET_APP: $TARGET_APP"
log "TARGET_WEB_PORT: $TARGET_WEB_PORT"
log "TARGET_WEB: $TARGET_WEB"

declare -A CHECKLAYOUTS_URLS
{%- set webapps = pillar['ufconfig']['applications'] %}
{%- for name in webapps %}{% set app = webapps[name] %}
{%- if 'checklayouts' in app %}
{%- set checklayouts = app['checklayouts'] %}
CHECKLAYOUTS_URLS["{{ name }}"]="{{ checklayouts['url'] }}"
{%- endif %}
{%- endfor %}

TARGET_HOSTS=${TARGET_APP[@]}
LAYOUT_CHECK_OK="Layout check OK"

CHECKLAYOUTS_URL=${CHECKLAYOUTS_URLS["${APP_NAME}"]}
for TARGET_HOST in ${TARGET_HOSTS}; do
  if [[ -n "$CHECKLAYOUTS_URL" ]]; then
    log "Calling checkLayouts: ${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$CHECKLAYOUTS_URL"
    RESPONSE=$(wget -q -O- "${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$CHECKLAYOUTS_URL")
    log "$RESPONSE"
    if [[ $RESPONSE != $LAYOUT_CHECK_OK ]]; then
      quit "Make sure that layouts have been uploaded and try again."
    else
      break
    fi
  fi
done

TARGET_APP_WITH_PORT=$(for TARGET in $TARGET_APP; do echo $TARGET:$TARGET_APP_PORT; done)
TARGET_WEB_WITH_PORT=$(for TARGET in $TARGET_WEB; do echo $TARGET:$TARGET_WEB_PORT; done)

# Start scripts on the targeted servers
if [ ! -z "$TARGET_APP" ]; then
	log "Starting execution of remote scripts on app-servers $TARGET_APP"
	salt -L "${TARGET_APP}" --async cmd.run "ufactivate-app-tomcat.sh $RANDOM_KEY $TARGET_APP_PORT $APP_NAME $APP_CONF $APP_VER"
fi

if [ ! -z "$TARGET_WEB" ]; then
 log "Starting execution of remote scripts on web-servers $TARGET_WEB"
 salt -L "${TARGET_WEB}" --async cmd.run "ufactivate-app-apache.sh $RANDOM_KEY $TARGET_WEB_PORT $APP_NAME $APP_CONF $APP_VER $TARGET_NAME"
fi

log "use 'salt-run jobs.lookup_jid <JID>' for info"

# Wait for all servers to begin deploy
log "Waiting for deploy started"
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=10 ${TARGET_APP_WITH_PORT} ${TARGET_WEB_WITH_PORT} || quit "START"
log "Deploy started"

# Wait for war-servers to deploy app, web-servers to copy files and dns server to add names
log "Waiting for STEP1..."
ufdeploy-coordinator --key "STEP1-DONE-${RANDOM_KEY}" --timeout=20 ${TARGET_APP_WITH_PORT} ${TARGET_WEB_WITH_PORT} || quit "STEP1"
log "STEP1 done"

if [ ! -z "$TARGET_WEB" ]; then
	# Wait for war-servers to deploy configuration and reload
	log "Waiting for STEP2..."
	ufdeploy-coordinator --key "STEP2-DONE-${RANDOM_KEY}" --timeout=20 ${TARGET_WEB_WITH_PORT} || quit "STEP2"
	log "STEP2 done"
fi

log "Logging activation"
echo "$DIST_NAME $(date)" >> /root/ufdist/activation.log

log "App $DIST_NAME activated"

log "Notifying Microsoft teams"
ufnotify-msteams.sh $0 $APP_NAME $DIST_NAME $LINKS
