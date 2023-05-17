#!/bin/bash

NEW_ACTIVE_SITE=$1

APP_SERVERS="ufcolo1-app1-ee ufcolo1-app2-ee ufcolo2-app1-ee ufcolo2-app2-ee"

if [[ $NEW_ACTIVE_SITE = "ufcolo1" ]]; then
  DB_PROMOTE_SERVERS="ufcolo1-dbmisc"
  DB_DEMOTE_SERVERS="ufcolo2-dbmisc"
elif [[ $NEW_ACTIVE_SITE = "ufcolo2" ]]; then
  DB_PROMOTE_SERVERS="ufcolo2-dbmisc"
  DB_DEMOTE_SERVERS="ufcolo1-dbmisc"
else
  echo Unknown site $NEW_ACTIVE_SITE
  exit 1
fi

RANDOM_KEY=$RANDOM
SYNC_PORT=8283

WEB_PORT=8182
DB_CLUSTER_NAME=ufoeeprod
DB_CLUSTER_VERSION=9.4
DB_SERVERS="${DB_PROMOTE_SERVERS} ${DB_DEMOTE_SERVERS}"

function quit {
  echo "$(date) SWITCHOVER FAILED: $1"
  exit 1
}

function log {
  echo "$(date) $1"
}

log "Switchover to site '${NEW_ACTIVE_SITE}'"
log "ee-servers: ${APP_SERVERS}"
log "Db-servers-promote: ${DB_PROMOTE_SERVERS}"
log "Db-servers-demote: ${DB_DEMOTE_SERVERS}"
log "Db-servers: ${DB_SERVERS}"
log "Db-cluster-version: ${DB_CLUSTER_VERSION}"
log "Db-cluster-name: ${DB_CLUSTER_NAME}"

# Start scripts on the targeted servers
log "Starting execution of remote scripts on ee-servers"
salt -L "${APP_SERVERS}" --async cmd.run "ufswitchover-ee-app.sh ${RANDOM_KEY} ${WEB_PORT}"
log "Starting execution of remote demote scripts on db-servers"
salt -L "${DB_DEMOTE_SERVERS}" --async cmd.run "ufswitchover-pgsql-demote.sh ${RANDOM_KEY} ${DB_CLUSTER_VERSION} ${DB_CLUSTER_NAME}"
log "Starting execution of remote promote scripts on db-servers"
salt -L "${DB_PROMOTE_SERVERS}" --async cmd.run "ufswitchover-pgsql-promote.sh ${RANDOM_KEY} ${DB_CLUSTER_VERSION} ${DB_CLUSTER_NAME}"

log "use 'salt-run jobs.lookup_jid <JID>' for info"
# Wait for all servers to begin switchover
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=30 --port=${SYNC_PORT} ${APP_SERVERS} ${DB_SERVERS} || quit "START"
log "Switchover started"

# Wait for app-servers to preform prepare
log "Prepareing ee-servers..."
ufdeploy-coordinator --key "APP-PREPARE-DONE-${RANDOM_KEY}" --timeout=10 --port=${SYNC_PORT} ${APP_SERVERS} ${DB_SERVERS} || quit "PREPARE"
log "App-servers prepared"
# Wait for db-servers to demote old master
log "Demoting db-servers..."
ufdeploy-coordinator --key "DB-DEMOTE-DONE-${RANDOM_KEY}" --timeout=20 --port=${SYNC_PORT} ${APP_SERVERS} ${DB_SERVERS} || quit "DEMOTE"
log "Db-servers demoted"
# Wait for db-servers to promote old slave
log "Promoting db-servers..."
ufdeploy-coordinator --key "DB-PROMOTE-DONE-${RANDOM_KEY}" --timeout=20 --port=${SYNC_PORT} ${APP_SERVERS} ${DB_SERVERS}
if [[ $? -ne 0 ]]; then
  log "DB-PROMOTE-DONE failed to sync, ignore and continue, old masters should detect if promote faild and be repromted"
else
log "Db-servers promoted"
fi
# Wait for app-servers to preform recover
log "Recover ee-servers"
ufdeploy-coordinator --key "APP-RECOVER-DONE-${RANDOM_KEY}" --timeout=20 --port=${SYNC_PORT} ${APP_SERVERS} || quit "RECOVER"
log "ee-servers recovered"
log "SWITCHOVER DONE"
