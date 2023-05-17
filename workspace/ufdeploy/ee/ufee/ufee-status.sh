#!/bin/bash

function quit {
  echo "$(date) SHOW STATUS FAILED: $1"
  exit 1
}

function log {
  echo "$(date) $1"
}

function change {
    RESULT=$(wget -q -O- "http://$1:$2/APPLICATION_STATUS?Set=$3")
    if [ -z "$RESULT" ]; then
        quit "Failed to change application status from $1 to $3"
    else
        log "Changed status for $1 to $3"
        log "Notifying Microsoft teams"
        ufswitchover-notify-msteams.sh "$0" "Changed status for $1 to $3" &
    fi   
}

ENV_PATH=$1
TARGET=$2
STATUS=$3

if [ -z "$ENV_PATH" ]; then
    quit "ufee-status.sh ufenv-ufoee-prod-ee.sh [ACTIVE ufcolo1-app1-ee]"
fi

if [ ! -f "$ENV_PATH" ]; then
    which "$ENV_PATH" > /dev/null || quit "Env file $ENV_PATH not found"
fi

source $ENV_PATH

ACTIVE_SERVER=
for APP_SERVER in $TARGET_APP; do
  RESULT=$(wget -q -O- "http://${APP_SERVER}:${TARGET_APP_WEB_PORT}/APPLICATION_STATUS")
  if [ -z "$RESULT" ]; then
    log "Failed to get application status from ${APP_SERVER}"
    ABORT=1
  else
    log "$APP_SERVER: $RESULT"
    if [[ $RESULT = "ACTIVE" ]]; then
        ACTIVE_SERVER=$APP_SERVER    
    fi
  fi
done

if [[ ABORT -eq 1 ]]; then
  exit 0;
fi

if [[ $STATUS = "ACTIVE" ]]; then
    log "Changing status of $TARGET to $STATUS using $ENV_PATH"
	if [ ! -z $ACTIVE_SERVER ]; then
	    log "Deactivating $ACTIVE_SERVER"
	    change ${ACTIVE_SERVER} ${TARGET_APP_WEB_PORT} "INACTIVE"
	fi
	
    change ${TARGET} ${TARGET_APP_WEB_PORT} $STATUS
elif [[ $STATUS = "INACTIVE" ]]; then
    log "Changing status of $TARGET to $STATUS using $ENV_PATH"
    change ${TARGET} ${TARGET_APP_WEB_PORT} $STATUS 
fi
