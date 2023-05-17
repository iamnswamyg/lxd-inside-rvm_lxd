#!/bin/bash
#set -x
function quit {
  echo "$(date) SWITCHOVER FAILED: $1"
  exit 1
}

function log {
  echo "$(date) $1"
}

NEW_ACTIVE_SITE=$1
DEPLOY_ENV_PATH=$2

if [ ! -f "$DEPLOY_ENV_PATH" ]; then
	which "$DEPLOY_ENV_PATH" > /dev/null || quit "Env file $DEPLOY_ENV_PATH not found"
fi

log "Sourcing $DEPLOY_ENV_PATH"
source $DEPLOY_ENV_PATH

RANDOM_KEY=$RANDOM

APP_SERVERS="$TARGET_APP"

DB_SERVERS_WITH_PORT=""

DB_FORCE_PROMOTE_SERVERS_TMP="$TARGET_DB_SERVER_FORCE_PROMOTE"
declare -A DB_PROMOTE_SERVER_MAP
for SERVER in ${TARGET_SITE_DB_SERVER_MAP[$NEW_ACTIVE_SITE]}; do
	MODE="STD"
	if [[ "$TARGET_DB_SERVER_FORCE_PROMOTE" =~ (^|[[:space:]])"$SERVER"($|[[:space:]]) ]]; then
		MODE="FORCE"
		DB_FORCE_PROMOTE_SERVERS_TMP=$(echo $DB_FORCE_PROMOTE_SERVERS_TMP | sed -r "s/(^|[[:space:]])$SERVER($|[[:space:]])/ /g")
	fi
	TMP=(${SERVER//:/ });
	SERVER_NAME=${TMP[0]}
	DB_PORT=${TMP[1]:=$TARGET_DB_PORT}
	DB_CLUSTER_NAME=${TMP[2]:=$TARGET_DB_CLUSTER_NAME}
	DB_CLUSTER_VERSION=${TMP[3]:=$TARGET_DB_CLUSTER_VERSION}
	KEY="${RANDOM_KEY} ${DB_PORT} ${DB_CLUSTER_VERSION} ${DB_CLUSTER_NAME} ${MODE}"
	DB_PROMOTE_SERVER_MAP[$KEY]="${DB_PROMOTE_SERVER_MAP[$KEY]} $SERVER_NAME"
	DB_SERVERS_WITH_PORT="$DB_SERVERS_WITH_PORT $SERVER_NAME:$DB_PORT"
done

declare -A DB_DEMOTE_SERVER_MAP
for SITE in $TARGET_SITE; do
	if [[ "$SITE" != "$NEW_ACTIVE_SITE" ]]; then
		for SERVER in ${TARGET_SITE_DB_SERVER_MAP[$SITE]}; do
			TMP=(${SERVER//:/ });
			SERVER_NAME=${TMP[0]}
			DB_PORT=${TMP[1]:=$TARGET_DB_PORT}
			DB_CLUSTER_NAME=${TMP[2]:=$TARGET_DB_CLUSTER_NAME}
			DB_CLUSTER_VERSION=${TMP[3]:=$TARGET_DB_CLUSTER_VERSION}
			KEY="${RANDOM_KEY} ${DB_PORT} ${DB_CLUSTER_VERSION} ${DB_CLUSTER_NAME} 15"
			DB_DEMOTE_SERVER_MAP[$KEY]="${DB_DEMOTE_SERVER_MAP[$KEY]} $SERVER_NAME" 
			DB_SERVERS_WITH_PORT="$DB_SERVERS_WITH_PORT $SERVER_NAME:$DB_PORT"
		done
	fi
done

if [[ -z ${TARGET_APP_WEB_PORT} ]]; then
    TARGET_APP_WEB_PORT=8080
fi


log "Switchover to site '${NEW_ACTIVE_SITE}'"
log "App-servers: ${APP_SERVERS}"
for KEY in "${!DB_PROMOTE_SERVER_MAP[@]}"; do
	log "Db-servers-promote-map: $KEY = ${DB_PROMOTE_SERVER_MAP[$KEY]}"
done
for KEY in "${!DB_DEMOTE_SERVER_MAP[@]}"; do
	log "Db-servers-demote-map: $KEY = ${DB_DEMOTE_SERVER_MAP[$KEY]}"
done
log "Db-servers-with-port: ${DB_SERVERS_WITH_PORT}"
log "Db-cluster-version: ${TARGET_DB_CLUSTER_VERSION}"
log "Db-cluster-name: ${TARGET_DB_CLUSTER_NAME}"
log "Db-pri-groups: ${TARGET_DB_PRI_GROUPS}"
log "Db-sec-groups: ${TARGET_DB_SEC_GROUPS}"


APP_SEVERS_WITH_PORT=$(for TARGET in $TARGET_APP; do echo $TARGET:$TARGET_APP_PORT; done)

if [[ ! "$TARGET_SITE" =~ (^|[[:space:]])"$NEW_ACTIVE_SITE"($|[[:space:]]) ]]; then
	quit "Invalid site: $NEW_ACTIVE_SITE, must be one of $TARGET_SITE"
fi

if [[ ! "$DB_FORCE_PROMOTE_SERVERS_TMP" =~ ^[[:space:]]*$ ]]; then
	quit "Specified force promote servers not found: $DB_FORCE_PROMOTE_SERVERS_TMP"
fi

#exit 1

# Start scripts on the targeted servers
log "Starting execution of remote scripts on app-servers"
salt -L "${APP_SERVERS}" --async cmd.run "ufswitchover-app.sh ${RANDOM_KEY} ${TARGET_APP_PORT} ${TARGET_APP_WEB_PORT} ${TARGET_DB_PRI_GROUPS} ${TARGET_DB_SEC_GROUPS}"

for KEY in "${!DB_DEMOTE_SERVER_MAP[@]}"; do
	log "Starting execution of remote demote scripts on db-servers for $KEY"
	salt -L "${DB_DEMOTE_SERVER_MAP[$KEY]}" --async cmd.run "ufswitchover-pgsql-demote.sh ${KEY}"
done

for KEY in "${!DB_PROMOTE_SERVER_MAP[@]}"; do
	log "Starting execution of remote promote scripts on db-servers for $KEY"
	salt -L "${DB_PROMOTE_SERVER_MAP[$KEY]}" --async cmd.run "ufswitchover-pgsql-promote.sh $KEY"
done

log "use 'salt-run jobs.lookup_jid <JID>' for info"
# Wait for all servers to begin switchover
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=30 ${APP_SEVERS_WITH_PORT} ${DB_SERVERS_WITH_PORT} || quit "START"
log "Switchover started"

# Wait for app-servers to preform prepare
log "Prepareing app-servers..."
ufdeploy-coordinator --key "APP-PREPARE-DONE-${RANDOM_KEY}" --timeout=10 ${APP_SEVERS_WITH_PORT} ${DB_SERVERS_WITH_PORT} || quit "PREPARE"
log "App-servers prepared"
# Wait for db-servers to demote old master
log "Demoting db-servers..."
ufdeploy-coordinator --key "DB-DEMOTE-DONE-${RANDOM_KEY}" --timeout=25 ${APP_SEVERS_WITH_PORT} ${DB_SERVERS_WITH_PORT} || quit "DEMOTE"
log "Db-servers demoted"
# Wait for db-servers to promote old slave
log "Promoting db-servers..."
ufdeploy-coordinator --key "DB-PROMOTE-DONE-${RANDOM_KEY}" --timeout=20 ${APP_SEVERS_WITH_PORT} ${DB_SERVERS_WITH_PORT}
if [[ $? -ne 0 ]]; then
  log "DB-PROMOTE-DONE failed to sync, ignore and continue, old masters should detect if promote faild and be repromted"
else
log "Db-servers promoted"
fi
# Wait for app-servers to preform recover
log "Recover app-servers"
ufdeploy-coordinator --key "APP-RECOVER-DONE-${RANDOM_KEY}" --timeout=20 ${APP_SEVERS_WITH_PORT} || quit "RECOVER"
log "App-servers recovered"
# TODO: Update dns servers?
log "SWITCHOVER DONE"
