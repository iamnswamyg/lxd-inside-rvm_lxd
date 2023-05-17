#!/bin/bash

function log {
  echo "$(date) $1"
}

VERSIONS=$(ufapp-list.sh ufo ufoweb test)
COUNT=$(echo "$VERSIONS" | grep -c "ufoweb-test.*")
TESTVERSIONS=$(echo "$VERSIONS" | grep -Eo "ufoweb-test.*")
ACTIVECOUNT=$(echo "$VERSIONS" | grep -Eo "ufoweb-test.*|Active" | grep -n "Active")

log "Starting auto undeploy"
log "Number of deployed versions found: $COUNT"

if [[ $COUNT -gt 2 && $ACTIVECOUNT != "2:Active" ]]; then
  VERSIONTOUNDEPLOY=$(echo $TESTVERSIONS | awk '{print $1}')

  log "Found one version to undeploy: $VERSIONTOUNDEPLOY"

  ufapp-undeploy.sh ufo $VERSIONTOUNDEPLOY
else
  log "No version found to undeploy."
fi

log "Done auto undeploy"
