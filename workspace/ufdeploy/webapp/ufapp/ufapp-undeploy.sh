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
  echo "ufapp-undeploy.sh <TARGET_NAME> <APP_NAME>-<APP_CONF>-<APP_VERSION>"
  echo "ufapp-undeploy.sh ufo ufoweb-test-201501010101"
  exit 1
fi

APPLICATION=$APP_NAME-$APP_CONF

DEPLOY_ENV_PATH=${ENV_FILE:-ufenv-${APP_NAME}-${APP_CONF}-${TARGET_NAME}.sh}

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
  which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

source $DEPLOY_ENV_PATH

TOMCAT_SERVERS=$TARGET_APP
echo "Application Servers: $TOMCAT_SERVERS"

ABORT=0
for APP_SERVER in $TOMCAT_SERVERS; do
  ACTIVE=$(wget -q -O- "http://unifaun:pasta@${APP_SERVER}:8080/fwdmanager/getactive?group=${APPLICATION}")
  if [[ $ACTIVE == $APP ]]; then
    echo "Version $APP is active on $APP_SERVER"
    ABORT=1
  fi
done

if [ $ABORT -eq 1 ]; then
  echo "Aborting undeploy."
  exit 1
fi

for APP_SERVER in $TOMCAT_SERVERS; do
  echo "Undeploying $APP on Tomcat: $APP_SERVER"
  wget -q -O- "http://unifaun:pasta@${APP_SERVER}:8080/manager/text/undeploy?path=/$APP"
done

echo "Undeploying $APP on Apache: ${TARGET_WEB}"

if [ ! -z "$TARGET_WEB" ]
then
        TARGET_WEB=$(echo $TARGET_WEB | tr ' ' ',')
        salt -L "$TARGET_WEB" cmd.run "/usr/local/bin/ufundeploy-apache.sh $APP_NAME $APP_CONF $APP_VER $TARGET_NAME \"$HTDOCS_SUBSITES\""
fi

echo "Notifying Microsoft teams"
ufnotify-msteams.sh $0 $APP_NAME ${APP} $LINKS
