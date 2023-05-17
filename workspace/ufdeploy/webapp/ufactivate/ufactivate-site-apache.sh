#!/bin/bash
HOSTNAME=$(hostname)

function quit {
  echo "$HOSTNAME $(date) ACTIVATE-SITE FAILED: $1"
  exit 1
}

function log {
  echo "$HOSTNAME $(date) $1"
}


RANDOM_KEY="$1"
SITE="$2"
STATUS="INACTIVE"
if [[ "$SITE" == "{{ site }}" ]]; then
  STATUS="ACTIVE"
fi

log "SITE: $SITE"
log "STATUS: $STATUS"

SYNC_PORT=8283
BIND9_DIR=/etc/bind


log "Setting site status to ${STATUS}"

# Cehck if file exists
if [ ! -f "/var/www/vhost/status/htdocs/SITE_STATUS" ]; then
  log "Missing file /var/www/vhost/status/htdocs/SITE_STATUS"
  ufdeploy-synchronizer --fail --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT}
  quit "Activate START failed"
fi

log "Waiting for START synch"
ufdeploy-synchronizer --key "START-${RANDOM_KEY}" --accept 10 --wait 10  --addr :${SYNC_PORT} || quit "START sync failed"

log "Setting site status to $STATUS"
echo $STATUS > /var/www/vhost/status/htdocs/SITE_STATUS

log "Waiting for STEP1-DONE synch"
ufdeploy-synchronizer --key "STEP1-DONE-${RANDOM_KEY}" --accept 10 --wait 30  --addr :${SYNC_PORT} || quit "STEP1-DONE sync failed"
