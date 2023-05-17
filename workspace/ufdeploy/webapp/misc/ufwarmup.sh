#!/bin/bash

function quit {
  echo "$(date) DEPLOY FAILED: $1"
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


if [[ ! "$SRC_PATH" == *.dist.tar ]]; then
  quit "Input file name must end with .dist.tar"
fi

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ] || [ -z "$TARGET_NAME" ] || [ ! -z "$EMPTY"]; then
  quit $'ufwarmup.sh path/<app_name>-<app_conf>-<app_ver>-<target_name>.tar\nufwarmup.sh /tmp/ufoweb-test-201407070949-ufo.tar'
fi

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
        which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

source $DEPLOY_ENV_PATH
TARGET_HOSTS=${TARGET_APP[@]}
log "TARGET_HOSTS: $TARGET_HOSTS"

declare -A WARMUP_URLS
{% set webapps = pillar['ufconfig']['applications'] %}
{% for name in webapps %}{% set app = webapps[name] %}{% if 'warmup' in app %}{% set warmup = app['warmup'] %}
WARMUP_URLS["{{ name }}"]="{{ warmup['url'] }}"
{% endif %}{% endfor %}

for TARGET_HOST in ${TARGET_HOSTS}; do
  WARMUP_URL=${WARMUP_URLS["${APP_NAME}"]}
  if [[ -n "$WARMUP_URL" ]]; then
    log "Calling warmup: ${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$WARMUP_URL"
    wget -q -O- "${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$WARMUP_URL"
  fi
done

log "Notifying Microsoft teams"
ufnotify-msteams.sh $0 $APP_NAME $DIST_NAME $LINKS
