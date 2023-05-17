#!/bin/bash

function log {
  echo "$(date) $1"
}

DIST_DIR="/tmp"

log "Starting auto deploy to testserver"

VERSION=$(curl -s -u devtv:devtv -k "http://10.13.16.31:9080/rest/api/2/project/UO/version?maxResults=10&orderBy=-releaseDate" | grep -Po '(?<="name":")[^"]*' | grep -E "^[0-9]{8}$" | sort -n | sed -n 1p)

if [ -z $VERSION ]; then
  log "Couldn't fetch version for autodeploy"
  exit 1
fi

# Check if version is correct format
date "+%Y%m%d" -d $VERSION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  log "Wrong version found $VERSION"
  exit 1 
fi

log "Found version $VERSION, starting build"

cd $DIST_DIR

uftest-build-jenkins.sh test-full "ufo/develop/v$VERSION" ufo ufo

if [ $? -ne 0 ]; then
  log "Failed to run jenkins build for version $VERSION, check jenkins"
  exit 1
fi

FILE=$(ls | grep "ufoweb-test-")

if [ ! -f $FILE ]; then
  log "Couldn't find file $FILE for deploy"
  exit 1
fi

ufdeploy.sh $FILE

if [ $? -ne 0 ]; then
  log "Failed to deploy $FILE, check logs"
  exit 1 
fi

ufactivate-app.sh $FILE

if [ $? -ne 0 ]; then
  log "Failed to activate $FILE, check logs"
  exit 1 
fi

rm $FILE

log "Done auto deploy"
