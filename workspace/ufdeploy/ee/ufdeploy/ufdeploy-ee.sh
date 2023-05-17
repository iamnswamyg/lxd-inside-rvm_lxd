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

if [ ! -f "$SRC_PATH" ]; then
  quit "File $SRC_PATH not found"
fi

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ] || [ -z "$TARGET_NAME" ] || [ ! -z "$EMPTY"]; then
  quit $'ufdeploy-ee.sh path/<app_name>-<app_conf>-<app_ver>-<target_name>.tar\nufdeploy-ee.sh /tmp/ufoee-test-201407070949-ee.tar'
fi

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
	which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

source $DEPLOY_ENV_PATH

log "TARGET_APP: $TARGET_APP"

# Check status of current servers
ACTIVE_SERVERS=0
log "Checking status of current servers"
for TARGET in $TARGET_APP; do
  STATUS_RESULT=$(eval "wget -q -O- \"http://${TARGET}:${TARGET_APP_WEB_PORT}/APPLICATION_STATUS\"")
  log "Status of application on $TARGET: $STATUS_RESULT"
  if [ "$STATUS_RESULT" == ACTIVE ]; then
    ((ACTIVE_SERVERS++))
  fi

  if [ "$STATUS_RESULT" == ACTIVE ] && [ $ACTIVE_SERVERS -gt 1  ]; then
    quit 'Only one application should be active. Please check configuration!'
  fi
done

# Moving files
log "Moving files from $SRC_PATH"
mkdir -p "$COPY_DIST_PATH"
if [[ "$(readlink -e $SRC_PATH)" != "${COPY_DIST_PATH}/${DIST_NAME}.dist.tar" ]]; then
	log "Copying ${DIST_NAME}.dist.tar to ${COPY_DIST_PATH}/${DIST_NAME}.dist.tar"
	cp "$SRC_PATH" "$COPY_DIST_PATH/${DIST_NAME}.dist.tar" || quit "Failed to copy file"
else
	log "${DIST_NAME}.dist.tar is located in ${COPY_DIST_PATH}, skipping copy"
fi
mkdir $SALT_DIST_PATH/$DIST_NAME
cp $SRC_PATH $SALT_DIST_PATH/$DIST_NAME/$DIST_NAME.dist.tar

# Transfere files
log "Transfering files"
for TARGET in $TARGET_APP; do
  transfer "$TARGET" "${DIST_NAME}.dist.tar"
done

# Deleteing files
log "Deleting files source"
rm -r "${SALT_DIST_PATH}/${DIST_NAME}"

# Start scripts on the targeted servers
log "Starting execution of remote scripts on ee-deploy-servers $TARGET_APP"
salt -L "${TARGET_APP}" --async cmd.run "ufdeploy-ee-app.sh $RANDOM_KEY $TARGET_APP_PORT $APP_NAME $APP_CONF $APP_VER $TARGET_NAME"

log "use 'salt-run jobs.lookup_jid <JID>' for info"

# Wait for all servers to begin deploy
log "Waiting for deploy started"
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=10 --port=${TARGET_APP_PORT} ${TARGET_APP} || quit "START"
log "Deploy started"

# Wait for servers to deploy app
log "Waiting for STEP1..."
ufdeploy-coordinator --key "STEP1-DONE-${RANDOM_KEY}" --timeout=20 --port=${TARGET_APP_PORT} ${TARGET_APP} || quit "STEP1"
log "STEP1 done"

log "App $DIST_NAME deployed"

log "Notifying Microsoft teams"
ufnotify-msteams.sh $0 $APP_NAME $DIST_NAME $LINKS
