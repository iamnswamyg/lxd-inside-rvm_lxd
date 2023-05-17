#!/bin/bash

function quit {
  echo "$(date) LIST VERSIONS FAILED: $1"
  exit 1
}

# Name of symolic link to this script should be ufee-list-<app_name>-<app_conf>-<app_target>.sh
CMD=$(basename -s ".sh" $0)
TMP1=(${CMD//-/ })
APP_CMD=${TMP1[0]}
APP_NAME=${TMP1[1]}
APP_CONF=${TMP1[2]}
APP_TARGET=${TMP1[3]}
EMPTY=${TMP1[4]}

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_TARGET" ] || [ ! -z "$EMPTY"]; then
    quit $'Invalid name of symbolic link to script'
fi

ENV_PATH="ufenv-${APP_NAME}-${APP_CONF}-${APP_TARGET}.sh"

if [ ! -f "$ENV_PATH" ]; then
    which "$ENV_PATH" > /dev/null || quit "Env file $ENV_PATH not found"
fi

source $ENV_PATH

TMP=
declare -A DEPLOYED_APPS
declare -A ACTIVE_APP
for APP_SERVER in $TARGET_APP; do
  RESULT=$(salt "$APP_SERVER" cmd.run "ls /usr/local/${APP_NAME}/" | grep -Eo "${APP_NAME}-[a-z]+-[0-9]+" | sort | uniq)
  if [ -z "$RESULT" ]; then
    echo "Failed to get deployed application from ${APP_SERVER}"
  else
    DEPLOYED_APPS["${APP_SERVER}"]=$RESULT
    TMP="$TMP $RESULT"
  fi
  ACTIVE=$(salt "$APP_SERVER" cmd.run "cat /usr/local/${APP_NAME}/bin/start.sh" | grep -Eo "${APP_NAME}-[a-z]+-[0-9]+")
  if [ -z "$ACTIVE" ]; then
    echo "Failed to get active application from ${APP_SERVER} for ${APP_NAME}"
  else
    ACTIVE_APP["${APP_SERVER}"]=$ACTIVE
  fi
done

TMP=$(echo $TMP | tr " " "\n" | sort | uniq)
for APP in $TMP; do
  echo "Application: $APP"
  for APP_SERVER in $TARGET_APP; do
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
      echo "  Running on: ${APP_SERVER}"
    fi
  done
done
