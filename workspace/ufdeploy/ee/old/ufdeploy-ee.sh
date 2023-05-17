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

EE_SERVERS="ufcolo1-app1-${TARGET_NAME} ufcolo1-app2-${TARGET_NAME} ufcolo2-app1-${TARGET_NAME} ufcolo2-app2-${TARGET_NAME}"

RANDOM_KEY=$RANDOM
SYNC_PORT=8283
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

# Check status of current servers
ACTIVE_SERVERS=0
log "Checking status of current servers"
for EE_SERVER in $EE_SERVERS; do
  STATUS_RESULT=$(eval "wget -q -O- \"http://${EE_SERVER}:8182/APPLICATION_STATUS\"")
  log "Status of application on $EE_SERVER: $STATUS_RESULT"
  if [ "$STATUS_RESULT" == ACTIVE ]; then
    ((ACTIVE_SERVERS++))
  fi

  if [ "$STATUS_RESULT" == ACTIVE ] && [ $ACTIVE_SERVERS -gt 1  ]; then
    quit 'Only one application should be active. Please check configuration!'
  fi
done

# Moving files
log "Moving files"
mkdir $SALT_DIST_PATH/$DIST_NAME
cp $SRC_PATH $SALT_DIST_PATH/$DIST_NAME/$DIST_NAME.dist.tar

# Transfere files
log "Transfering files"
for EE_SERVER in $EE_SERVERS; do
  transfer "$EE_SERVER" "${DIST_NAME}.dist.tar"
done

# Deleteing files
log "Deleting files source"
rm -r "${SALT_DIST_PATH}/${DIST_NAME}"

# Start scripts on the targeted servers
log "Starting execution of remote scripts on ee-deploy-servers $EE_SERVERS"
salt -L "${EE_SERVERS}" --async cmd.run "ufdeploy-ee-app.sh $RANDOM_KEY $APP_NAME $APP_CONF $APP_VER $TARGET_NAME"

log "use 'salt-run jobs.lookup_jid <JID>' for info"

# Wait for all servers to begin deploy
log "Waiting for deploy started"
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=10 --port=${SYNC_PORT} ${EE_SERVERS} || quit "START"
log "Deploy started"

# Wait for servers to deploy app
log "Waiting for STEP1..."
ufdeploy-coordinator --key "STEP1-DONE-${RANDOM_KEY}" --timeout=20 --port=${SYNC_PORT} ${EE_SERVERS} || quit "STEP1"
log "STEP1 done"

log "App $DIST_NAME deployed"
