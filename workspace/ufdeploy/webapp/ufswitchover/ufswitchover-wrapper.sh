#!/bin/bash

function quit {
  echo "$(date) DEPLOY FAILED: $1"
  exit 1
}

NEW_ACTIVE_SITE=$1

# Name of symolic link to this script should be ufswitchover-<app_name>-<app_conf>-<app_target>.sh
CMD=$(basename -s ".sh" $0)
TMP1=(${CMD//-/ })
APP_CMD=${TMP1[0]}
APP_NAME=${TMP1[1]}
APP_CONF=${TMP1[2]}
APP_TARGET=${TMP1[3]}
EMPTY=${TMP1[4]}


if [ -z "$NEW_ACTIVE_SITE" ] ; then
	quit "Must specify site to active as only argument"
fi

if [[ "$APP_CMD" != "ufswitchover" ]] || [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_TARGET" ] || [ ! -z "$EMPTY"]; then
	quit $'Invalid name of symbolic link to script, should be "ufswitchover-<app_name>-<app_conf>-<app_target>.sh"'
fi

ufswitchover.sh "$NEW_ACTIVE_SITE" "ufenv-${APP_NAME}-${APP_CONF}-${APP_TARGET}.sh" 

echo "$(date) Notifying Microsoft teams"
ufswitchover-notify-msteams.sh "$0" "application switchover done" &

exit 0
