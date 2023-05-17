#!/bin/bash

function quit {
  echo "$(date) ACTIVATE SITE FAILED: $1"
  exit 1
}

function log {
  echo "$(date) $1"
}


SITE=$1
EMPTY=$2

log "SITE: $SITE"

WEB_SERVERS="{{ webServers | join(' ') }}"
DNS_SERVERS="ufcolo1-app1 ufcolo1-app2 ufcolo2-app1 ufcolo2-app2 ufcolo1-dmzprod1-dns1 ufcolo1-dmzprod2-dns1 ufcolo1-dmzprod3-dns1 ufcolo2-dmzprod1-dns1 ufcolo2-dmzprod2-dns1 ufcolo2-dmzprod3-dns1 aws1-dns1 aws1-dns2"

PILLAR_PATH="/srv/saltstack/global_pillar"

SYNC_PORT=8283
RANDOM_KEY=$RANDOM

if [ -z "$SITE" ] || [ ! -z "$EMPTY"]; then
  quit $'ufactivate-site.sh [ufcolo1|ufcolo2]'
fi

if [[ "$SITE" != "ufcolo1" ]] && [[ "$SITE" != "ufcolo2" ]]; then
  quit "Invalid site argument: '$SITE', only 'ufcolo1' or 'ufcolo2' is valid values"
fi

# Changed 2022-02-18 by linusa to ensure that the file is up to date on both salt masters.
# Previously the 'salt' line below was done in this way:
# > echo "active_site: ${SITE}" > ${PILLAR_PATH}/active_site.sls
# This change should ensure that both salt masters have an updated SLS for active_site

# Changed again 2022-11-03 to include aws-salt[12] via *-salt[12]

log "Setting active_site in global pillar on ufoffice-salt[12]"
salt *-salt[12] cmd.run "echo 'active_site: ${SITE}' > ${PILLAR_PATH}/active_site.sls"

FILES_VERIFIED=$(salt *-salt[12] cmd.run "cat ${PILLAR_PATH}/active_site.sls" | grep ${SITE} | wc -l)

# FILES_VERIFIED should be equal to 4, since all nodes should have the same, new value.
# if this is not the case, we warn about this but do not exit.

# TODO: When ufoffice no longer exists, this will again be '2'

if [ "$FILES_VERIFIED" -ne 4 ]; then
  log "WARNING: check ${PILLAR_PATH}/active_site.sls on *-salt[12] manually, they don't seem to agree on ${SITE}"
fi

#log "Transfereing dns-zone file"
#salt -L "${WEB_SERVERS}" --out txt cp.get_template "salt://bind9/db.transportalen.se" "/tmp/db.transportalen.se.${RANDOM_KEY}" context="{ active_site: ${SITE} }"

# Updating Excedo DNS records
log "Starting update of Excedo DNS zones"
/usr/local/bin/excedo_switchover.sh $SITE
log "Finished update of Excedo DNS zones"

# Start scripts on the targeted servers
log "Starting execution of remote scripts on web-servers $WEB_SERVERS"
salt -L "${WEB_SERVERS}" --async cmd.run "ufactivate-site-apache.sh $RANDOM_KEY $SITE"
log "Starting execution of remote scripts on pure dns-servers $DNS_SERVERS"
salt -L "${DNS_SERVERS}" --async cmd.run "ufactivate-site-dns.sh $RANDOM_KEY $SITE"

log "use 'salt-run jobs.lookup_jid <JID>' for info"

# Wait for all servers to begin deploy
log "Waiting for deploy started"
ufdeploy-coordinator --key "START-${RANDOM_KEY}" --timeout=10 --port=${SYNC_PORT} ${WEB_SERVERS} ${DNS_SERVERS} || quit "START"
log "Deploy started"

# Wait for web-servers to update the /var/www/vhost/status/htdocs/SITE_STATUS file and servers with bind9 to update dns.

log "Waiting for STEP1..."
ufdeploy-coordinator --key "STEP1-DONE-${RANDOM_KEY}" --timeout=20 --port=${SYNC_PORT} ${WEB_SERVERS} ${DNS_SERVERS} || quit "STEP1"
log "STEP1 done"

log "Site $SITE activated"

log "Notifying Microsoft teams"
ufswitchover-notify-msteams.sh "$0" "site $SITE activated" &

exit 0
