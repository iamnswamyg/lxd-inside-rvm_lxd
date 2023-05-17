#!/bin/bash
# Program to undeploy configuration in apache
# Martin Häggström 190405
#
# run like ufundeploy-apache.sh bobweb prod 201905070813 bob "admin client old" or
# ufundeploy-apache.sh ufoweb prod 201904261401 ufo
#

HOSTNAME=$(hostname)
APP_NAME=$1
APP_CONF=$2
APP_VER=$3
TARGET_NAME=$4
HTDOCS_SUBSITES=$5
SCRIPTNAME=$(basename "$0")

function quit {
  echo "$HOSTNAME $(date) UNDEPLOY FAILED: $1"
  exit 1
}

function log {
  echo "$HOSTNAME $(date) $1"
}

function delete {

	FILE_PATH=$1

	log "rm -R ${FILE_PATH}"
        rm -R "${FILE_PATH}"
        [ $? != 0 ] && log "Couldn't delete ${FILE_PATH}"
}

if [ -z "$APP_NAME" ] || [ -z "$APP_CONF" ] || [ -z "$APP_VER" ] || [ -z "$TARGET_NAME" ]; then
  echo "$SCRIPTNAME <APP_NAME> <APP_CONF> <APP_VER> <TARGET_NAME> <HTDOCS_SUBSITES>"
  echo "$SCRIPTNAME ufoweb test 201501010101 ufo"
  quit
fi

log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"
log "HTDOCS_SUBSITES: $HTDOCS_SUBSITES"

LONG_NAME=${APP_NAME}-${APP_CONF}-${APP_VER}-${TARGET_NAME}

log "Udeploying ${LONG_NAME} from Apache"

SITES_AVAILABLE=/etc/apache2/sites-available
DOCUMENT_ROOT=/var/www/vhost

FILE_PATH="${SITES_AVAILABLE}/${LONG_NAME}-ssl.conf"
if [ -f $FILE_PATH ]
then
	log "a2dissite ${LONG_NAME}-ssl.conf"
	log "service apache2 reload"
	a2dissite ${LONG_NAME}-ssl.conf
	service apache2 reload

	delete ${FILE_PATH}
else
	log "$FILE_PATH doesn't exist"
fi

FILE_PATH="${SITES_AVAILABLE}/${LONG_NAME}"
if [ -d "$FILE_PATH" ]
then
	delete ${FILE_PATH}
else
	log "$FILE_PATH doesn't exist"
fi

if [ "$HTDOCS_SUBSITES"x = x ]
then
	FILE_PATH="${DOCUMENT_ROOT}/${APP_NAME}/${APP_NAME}-${APP_CONF}-${APP_VER}"
	if [ -d "$FILE_PATH" ]
	then
		delete ${FILE_PATH}
	else
		log "$FILE_PATH doesn't exist"
	fi
else
	for SUBSITE in $HTDOCS_SUBSITES
	do
		FILE_PATH="${DOCUMENT_ROOT}/${APP_NAME}/${SUBSITE}/${APP_NAME}-${APP_CONF}-${APP_VER}"
		if [ -d "$FILE_PATH" ]
		then
			delete ${FILE_PATH}
		else
			log "$FILE_PATH doesn't exist"
		fi
	done
fi

exit 0