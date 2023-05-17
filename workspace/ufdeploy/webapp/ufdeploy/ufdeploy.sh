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

DEPLOY_ENV_PATH=${2:-ufenv-${APP_NAME}-${APP_CONF}-${TARGET_NAME}.sh}

log "DIST_NAME: $DIST_NAME"
log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"

RANDOM_KEY=$RANDOM
COPY_DIST_PATH="/root/ufdist/${APP_NAME}-${APP_CONF}"
SALT_DIST_PATH="/srv/saltstack/salt/ufdeploy/dist"


if [[ ! "$SRC_PATH" == *.dist.tar ]]; then
	quit "Input file name must end with .dist.tar"
fi

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ] || [ -z "$TARGET_NAME" ] || [ ! -z "$EMPTY"]; then
	quit $'ufdeploy.sh path/<app_name>-<app_conf>-<app_ver>-<target_name>.tar\nufdeploy.sh /tmp/ufoweb-test-201407070949-ufo.tar'
fi

if [ ! -f "$SRC_PATH" ]; then
	quit "Dist file $SRC_PATH not found"
fi

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
	which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

source $DEPLOY_ENV_PATH

log "TARGET_WAR_PORT: $TARGET_WAR_PORT"
log "TARGET_WAR: $TARGET_WAR"
log "TARGET_WEB_PORT: $TARGET_WEB_PORT"
log "TARGET_WEB: $TARGET_WEB"

log "TARGET_DNS_PORT: $TARGET_DNS_PORT"
log "TARGET_DNS: $TARGET_DNS"

log "HTDOCS_SUBSITES: $HTDOCS_SUBSITES"

TARGET_WAR_WITH_PORT=$(for TARGET in $TARGET_WAR; do echo $TARGET:$TARGET_WAR_PORT; done)
TARGET_WEB_WITH_PORT=$(for TARGET in $TARGET_WEB; do echo $TARGET:$TARGET_WEB_PORT; done)
TARGET_DNS_WITH_PORT=$(for TARGET in $TARGET_DNS; do echo $TARGET:$TARGET_DNS_PORT; done)

TARGET_WAR_WITH_APP=$(for WAR in ${!TARGET_WAR_APP_MAP[@]}; do for APP in ${TARGET_WAR_APP_MAP[$WAR]}; do echo $WAR:$APP; done; done)
log "TARGET_WAR_WITH_APP: $TARGET_WAR_WITH_APP"

# Extract files
log "Extracting files from $SRC_PATH"
mkdir -p "$COPY_DIST_PATH"
if [[ "$(readlink -e $SRC_PATH)" != "${COPY_DIST_PATH}/${DIST_NAME}.dist.tar" ]]; then
	log "Copying ${DIST_NAME}.dist.tar to ${COPY_DIST_PATH}/${DIST_NAME}.dist.tar"
	cp "$SRC_PATH" "$COPY_DIST_PATH/${DIST_NAME}.dist.tar" || quit "Failed to copy file"
else
	log "${DIST_NAME}.dist.tar is located in ${COPY_DIST_PATH}, skipping copy"
fi
tar -xf "$COPY_DIST_PATH/${DIST_NAME}.dist.tar" --directory "$SALT_DIST_PATH" || exit "Failed to extract files from $COPY_DIST_PATH/${DIST_NAME}.dist.tar"

if [[ ! -z "$TARGET_DNS" && ! -f "${SALT_DIST_PATH}/${DIST_NAME}/${DIST_NAME}.nsupdate.txt" ]]; then
	quit "Missing file ${DIST_NAME}.nsupdate.txt"
fi

if [[ ! -z "$TARGET_WAR" && ! -f "${SALT_DIST_PATH}/${DIST_NAME}/${DIST_NAME}.app.war" ]]; then
	quit "Missing file ${DIST_NAME}.app.war"
fi

if [[ ! -z "$TARGET_WEB" && ! -f "${SALT_DIST_PATH}/${DIST_NAME}/${DIST_NAME}.web.tar.gz" ]]; then
	quit "Missing file ${DIST_NAME}.web.tar.gz"
fi

# Transfere files
log "Transfering files"
if [ ! -z "$TARGET_DNS" ]; then
	for DNS_SERVER in $TARGET_DNS; do
		transfer "$TARGET_DNS" "${DIST_NAME}.nsupdate.txt"
	done
fi

if [ ! -z "$TARGET_WAR" ]; then
	for WAR_SERVER in $TARGET_WAR; do
		transfer "$WAR_SERVER" "${DIST_NAME}.app.war"
	done
fi

if [ ! -z "$TARGET_WEB" ]; then
	for WEB_SERVER in $TARGET_WEB; do
		transfer "$WEB_SERVER" "${DIST_NAME}.web.tar.gz"
	done
fi

# Deleteing files
log "Deleting files source"
rm -r "${SALT_DIST_PATH}/${DIST_NAME}"

# AFTER file transfer, but BEFORE host-based scripts:
# DRIFT-1591 workaround for applying xml symlinks *only* if:
# 1. Receiving container is running 22.04
# 2. Deploy is happening for ufoweb-prod

if [[ $APP_NAME == "ufoweb" ]] && [[ $APP_CONF == "prod" ]]; then
  log "This is a ufoweb 'prod' deployment. Running SYMLINK_COMMAND for 22.04 containers, if any."
  
  # CONTAINER_LIST is just like TARGET_APP (aka TARGET_HOSTS) but comma-separated.
  # This is required for salt as it doesn't accept space separated lists
  
  CONTAINER_LIST="$(echo $TARGET_APP | sed -e 's/ /,/g')"
  
  # Run SYMLINK_COMMAND on 22.04 containers *only*
  # Logic is handled by salt which takes a list of all containers, then filters on osrelease '22.04'
  # Assuming the config symlink should be named ${APP_NAME}-${APP_CONF}-${APP_VER} : like "ufoweb-test-201407070949"
  # the tomcat-tar state ensures override-context.xml is available on the container.
  
  # This was tested with file.symlink but since 'force' did not work as expected I'm opting for cmd.run
  
  SYMLINK_COMMAND="ln --symbolic --force \
  /opt/tomcat/override-context.xml \
  /opt/tomcat/conf/Catalina/localhost/${APP_NAME}-${APP_CONF}-${APP_VER}.xml"
  
  salt -C "L@$CONTAINER_LIST and G@osrelease:22.04" cmd.run "$SYMLINK_COMMAND"
  RETCODE=$?
  
  # Salt exit codes: 0 = ALL or SOME matched, 2 = NONE matched
  # None of these codes causes this script to bail.
  
  [[ $RETCODE -eq 0 ]] && log "Retcode 0: SYMLINK_COMMAND ran successfully on one or more nodes."
  [[ $RETCODE -eq 2 ]] && log "Retcode 2: SYMLINK_COMMAND DID NOT RUN, probably no 22.04 containers available."
fi

# Start scripts on the targeted servers
if [ ! -z "$TARGET_DNS" ]; then
	log "Starting execution of remote script on dns-server $TARGET_DNS"
	salt -L "${TARGET_DNS}" --async cmd.run "ufdeploy-dns.sh $RANDOM_KEY $TARGET_DNS_PORT $APP_NAME $APP_CONF $APP_VER $TARGET_NAME"
fi

if [ ! -z "$TARGET_WAR" ]; then
	log "Starting execution of remote scripts on war-deploy-servers $TARGET_WAR"
	salt -L "${TARGET_WAR}" --async cmd.run "ufdeploy-warstaging.sh $RANDOM_KEY $TARGET_WAR_PORT $APP_NAME $APP_CONF $APP_VER $TARGET_NAME \"$TARGET_WAR_WITH_APP\""
fi

if [ ! -z "$TARGET_WEB" ]; then
	log "Starting execution of remote scripts on web-servers $TARGET_WEB"
	salt -L "${TARGET_WEB}" --async cmd.run "ufdeploy-apache.sh $RANDOM_KEY $TARGET_WEB_PORT $APP_NAME $APP_CONF $APP_VER $TARGET_NAME \"$HTDOCS_SUBSITES\""
fi

log "use 'salt-run jobs.lookup_jid <JID>' for info"

# Wait for all servers to begin deploy
log "Waiting for deploy started"
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=10 ${TARGET_WAR_WITH_PORT} ${TARGET_WEB_WITH_PORT} ${TARGET_DNS_WITH_PORT} || quit "START"
log "Deploy started"

# Wait for war-servers to deploy app, web-servers to copy files and dns server to add names
log "Waiting for STEP1..."
ufdeploy-coordinator --key "STEP1-DONE-${RANDOM_KEY}" --timeout=120 ${TARGET_WAR_WITH_PORT} ${TARGET_WEB_WITH_PORT} ${TARGET_DNS_WITH_PORT} || quit "STEP1"
log "STEP1 done"

if [ ! -z "$TARGET_WEB" ]; then
 # Wait for war-servers to deploy configuration and reload
 log "Waiting for STEP2..."
 ufdeploy-coordinator --key "STEP2-DONE-${RANDOM_KEY}" --timeout=40 ${TARGET_WEB_WITH_PORT} || quit "STEP2"
 log "STEP2 done"
fi

declare -A WARMUP_URLS
{% set webapps = pillar['ufconfig']['applications'] %}
{% for name in webapps %}{% set app = webapps[name] %}{% if 'warmup' in app %}{% set warmup = app['warmup'] %}
WARMUP_URLS["{{ name }}"]="{{ warmup['url'] }}"
{% endif %}{% endfor %}

TARGET_HOSTS=${TARGET_APP[@]}

for TARGET_HOST in ${TARGET_HOSTS}; do
  WARMUP_URL=${WARMUP_URLS["${APP_NAME}"]}
  if [[ -n "$WARMUP_URL" ]]; then
    log "Calling warmup: ${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$WARMUP_URL"
    wget -q -O- "${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$WARMUP_URL"
  fi
done

declare -A UPLOADLAYOUTS_URLS
{% set webapps = pillar['ufconfig']['applications'] %}
{% for name in webapps %}{% set app = webapps[name] %}{% if 'uploadlayouts' in app %}{% set uploadlayouts = app['uploadlayouts'] %}
UPLOADLAYOUTS_URLS["{{ name }}"]="{{ uploadlayouts['url'] }}"
{% endif %}{% endfor %}

TARGET_HOSTS=${TARGET_APP[@]}

for TARGET_HOST in ${TARGET_HOSTS}; do
  UPLOADLAYOUTS_URL=${UPLOADLAYOUTS_URLS["${APP_NAME}"]}
  if [[ -n "$UPLOADLAYOUTS_URL" ]]; then
    log "Calling uploadLayouts: ${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$UPLOADLAYOUTS_URL"
    wget -q -O- "${TARGET_HOST}.ufprod.lan:8080/${APP_NAME}-${APP_CONF}-${APP_VER}/$UPLOADLAYOUTS_URL"
  fi
done

log "App $DIST_NAME deployed"

log "Notifying Microsoft teams"
ufnotify-msteams.sh $0 $APP_NAME $DIST_NAME $LINKS
