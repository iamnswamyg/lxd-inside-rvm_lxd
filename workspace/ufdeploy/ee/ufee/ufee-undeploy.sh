#!/bin/bash

function quit {
  echo "FAILED: $1"
  exit 1
}

TARGET_NAME=$1
APP=$2

TMP1=(${APP//-/ })
APP_NAME=${TMP1[0]}
APP_CONF=${TMP1[1]}
APP_VER=${TMP1[2]}

if [ -z "$TARGET_NAME" ] || [ -z "$APP" ] || [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ]; then
  echo "ufee-undeploy.sh <TARGET_NAME> <APP_NAME>-<APP_CONF>-<APP_VERSION>"
  echo "ufee-undeploy.sh ee ufoee-prod-201501010101"
  exit 1
fi

APPLICATION=$APP_NAME-$APP_CONF

DEPLOY_ENV_PATH=${ENV_FILE:-ufenv-${APP_NAME}-${APP_CONF}-${TARGET_NAME}.sh}

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
  which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

source $DEPLOY_ENV_PATH

EE_SERVERS=$TARGET_APP
echo "Application Servers: $EE_SERVERS"

ABORT=0
for EE_SERVER in $EE_SERVERS; do
  ACTIVE=$(salt "$EE_SERVER" cmd.run "cat /usr/local/${APP_NAME}/bin/start.sh" | grep -Eo "${APP_NAME}-[a-z]+-[0-9]+")
  if [[ $ACTIVE == $APP ]]; then
    echo "Version $APP is active on $EE_SERVER"
    ABORT=1
  fi
done

if [ $ABORT -eq 1 ]; then
  echo "Aborting undeploy."
  exit 1
fi

for EE_SERVER in $EE_SERVERS; do
  echo "Undeploying $APP on $EE_SERVER"
  salt "$EE_SERVER" cmd.run "rm -r /usr/local/${APP_NAME}/${APP}"
done

echo "Notifying Microsoft teams"
ufnotify-msteams.sh $0 $APP_NAME ${APP} $LINKS
