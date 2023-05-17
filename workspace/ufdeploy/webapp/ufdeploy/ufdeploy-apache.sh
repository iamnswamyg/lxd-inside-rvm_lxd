#!/bin/bash
HOSTNAME=$(hostname)

function quit {
  echo "$HOSTNAME $(date) DEPLOY FAILED: $1"
  exit 1
}

function log {
  echo "$HOSTNAME $(date) $1"
}

RANDOM_KEY="$1"
SYNC_PORT="$2"
APP_NAME="$3"
APP_CONF="$4"
APP_VER="$5"
TARGET_NAME="$6"
HTDOCS_SUBSITES="$7"

log "APP_NAME: $APP_NAME"
log "APP_CONF: $APP_CONF"
log "APP_VER: $APP_VER"
log "TARGET_NAME: $TARGET_NAME"
log "HTDOCS_SUBSITES: $HTDOCS_SUBSITES"

LONG_NAME=${APP_NAME}-${APP_CONF}-${APP_VER}-${TARGET_NAME}

log "Deploying ${LONG_NAME} to apache"

# Cehck if file exists
if [ ! -f "/tmp/${LONG_NAME}.web.tar.gz" ]; then
  log "Missing file /tmp/${LONG_NAME}.web.tar.gz"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Deploy START failed"
fi

log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "START sync failed"

log "Unpack files"
if [ -d "/tmp/${LONG_NAME}" ]; then
  rm -r /tmp/${LONG_NAME}
fi
mkdir /tmp/${LONG_NAME}
tar -xzf /tmp/${LONG_NAME}.web.tar.gz --directory /tmp/${LONG_NAME}
if  [ $? -ne 0 ]; then
  log "Failed to unpack files"
  ufdeploy-synchronizer --fail --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 120  --addr :${SYNC_PORT}
  quit "Deploy STEP1-DONE failed"
fi


log "Copy site documents"
if [ "$HTDOCS_SUBSITES"x = x ]
then
	mkdir -p /var/www/vhost/${APP_NAME}
	cp -r /tmp/${LONG_NAME}/htdocs/* /var/www/vhost/${APP_NAME}/
else
	for SUBSITE in $HTDOCS_SUBSITES
	do
		mkdir -p /var/www/vhost/${APP_NAME}/${SUBSITE}
		if [ -d /tmp/${LONG_NAME}/htdocs/${SUBSITE} ]
		then
			log "copy /tmp/${LONG_NAME}/htdocs/${SUBSITE}/* to /var/www/vhost/${APP_NAME}/${SUBSITE}"
			cp -r /tmp/${LONG_NAME}/htdocs/${SUBSITE}/* /var/www/vhost/${APP_NAME}/${SUBSITE}
		else
			log "/tmp/${LONG_NAME}/htdocs/${SUBSITE} doesn't exist"
		fi
	done
fi

log "Copy configuration"
mkdir /etc/apache2/sites-available/${LONG_NAME}
cp /tmp/${LONG_NAME}/vhosts/* /etc/apache2/sites-available/${LONG_NAME}/
cp /tmp/${LONG_NAME}/vhosts/${LONG_NAME}-*.conf /etc/apache2/sites-available/

if [ -f "/tmp/${LONG_NAME}/${LONG_NAME}.nsupdate.txt" ]; then
  log "Updating dns"
  nsupdate "/tmp/${LONG_NAME}/${LONG_NAME}.nsupdate.txt"
fi

log "Waiting for STEP1-DONE synch"
ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 50  --addr :${SYNC_PORT} || quit "STEP1-DONE sync failed"
log "Enable sites"
SITES=$(ls /etc/apache2/sites-available/${LONG_NAME}/ | grep "^${LONG_NAME}-.*\.conf$" | sed "s/\.conf//g")
for SITE in $SITES; do
  log "Enable site ${SITE}"
  a2ensite "$SITE"
done
log "Reload apache configuration"
service apache2 reload

ufdeploy-synchronizer --key "STEP2-DONE-${RANDOM_KEY}" --accept 10 --wait 50  --addr :${SYNC_PORT} || quit "STEP2-DONE sync failed"

echo "Cleanup"
rm /tmp/${LONG_NAME}.web.tar.gz
rm -r /tmp/${LONG_NAME}

