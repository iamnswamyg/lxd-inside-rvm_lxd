#!/bin/bash

function quit {
  echo "FAILED: $1"
  exit 1
}

TARGET_NAME=$1
APP_NAME=$2
APP_CONF=$3
ENV_FILE=$4

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$TARGET_NAME" ]; then
  echo "ufapp-list.sh <TARGET_NAME> <APP_NAME> <APP_CONF>"
  echo "uflist-apps.sh ufo ufoweb test"
  echo "uflist-apps.sh bob bobweb prod"
  echo "uflist-apps.sh lars ufoweb devtest"
  echo "TARGET_NAME: ufo hit bob ee ufofs"
  echo "APP_NAME: ufoweb bobweb"
  echo "APP_CONF: prod test devtest"

  exit 1
fi

DEPLOY_ENV_PATH=${ENV_FILE:-ufenv-${APP_NAME}-${APP_CONF}-${TARGET_NAME}.sh}

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
  which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

source $DEPLOY_ENV_PATH

TOMCAT_SERVERS=$TARGET_APP
echo "Application Servers: $TOMCAT_SERVERS"

TMP=
declare -A DEPLOYED_APPS
declare -A ACTIVE_APP
for APP_SERVER in $TOMCAT_SERVERS; do
  RESULT=$(wget --timeout=30 -q -O- "http://unifaun:pasta@${APP_SERVER}:8080/manager/text/list" | grep -Eo "${APP_NAME}-${APP_CONF}-[0-9]+" | sort | uniq)
  if [ $? -ne 0 ]; then
    echo "Failed to get deployed application from ${APP_SERVER}"
  else
    DEPLOYED_APPS["${APP_SERVER}"]=$RESULT
    TMP="$TMP $RESULT"
  fi
  ACTIVE=$(wget --timeout=30 -q -O- "http://unifaun:pasta@${APP_SERVER}:8080/fwdmanager/getactive?group=${APP_NAME}-${APP_CONF}")
  if [ $? -ne 0 ]; then
    echo "Failed to get active application from ${APP_SERVER} for ${APP_NAME}-${TARGET_NAME}"
  else
    ACTIVE_APP["${APP_SERVER}"]=$ACTIVE
  fi
done

TMP=$(echo $TMP | tr " " "\n" | sort | uniq)
COUNT=0
for APP in $TMP; do
  ((COUNT=COUNT+1))
  echo "Application: $APP"
  for APP_SERVER in $TOMCAT_SERVERS; do
    FOUND=1
    for TMP_APP in ${DEPLOYED_APPS["$APP_SERVER"]}; do
      if [[ $APP == $TMP_APP ]]; then
        FOUND=0
      fi
    done
    if [ $FOUND -eq 1 ]; then
      echo " Missing on: ${APP_SERVER}"
    fi
    if [[ $APP == ${ACTIVE_APP["$APP_SERVER"]} ]]; then
      echo "  Active on: ${APP_SERVER}"
    fi
  done
done

if [ $COUNT -gt 2 ]; then
    echo
    echo
    echo "ATTENTION: There are more than 2 versions deployed ($COUNT). Seriously consider undeploying!"
    echo
    echo
fi
