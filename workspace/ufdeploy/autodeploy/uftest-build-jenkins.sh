#!/bin/bash

function log {
  echo "$(date) $1"
}

ANTTARGET=$1
BRANCH=$2
APP=$3
DISTTARGET=$4

JOB=ufoweb-params
USER=unifaun
TOKEN=5f92f2f712c5c264542dd65f631ba4e9
JENKINS="http://10.10.0.13:8082/job/"

if [ -z $ANTTARGET ]; then
  log "Missing ant target: devtest-full, exttest-full, prod, test-full, ..."
  exit 1
fi

if [ -z $BRANCH ]; then
  log "Missing branch name: master, ufo/develop/20160921, ..."
  exit 1
fi

log "Starting jenkins job $JOB"

curl -f -s -X POST --user $USER:$TOKEN "$JENKINS$JOB/buildWithParameters?ANTTARGET=$ANTTARGET&BRANCH=$BRANCH&APP=$APP&DISTTARGET=$DISTTARGET" || log "Failed to run $JOB with correct parameters, please check jenkins" || exit 1

sleep 10

PROGRESS=0
until [ $PROGRESS -eq 100 ]; do
  PROGRESS=`curl -s "$JENKINS$JOB/lastBuild/api/json?tree=executor[progress]" --globoff | sed -e 's/[{}]/''/g' | cut -d: -f4`
  if [ -z $PROGRESS ]; then
    break
  fi
  # Check that $PROGRESS is a number
  if ! [ "$PROGRESS" -eq "$PROGRESS" ] 2> /dev/null; then
    log "Jenkins is returning garbage: $PROGRESS"
    exit 1
  fi
  echo -ne "$(date) Running jenkins job $JOB: $PROGRESS %\r\c"
  sleep 4
done
echo -ne "\n"

log "Done with build of $JOB"
DIST_FILE=$(curl -s "$JENKINS$JOB/lastBuild/api/xml" | grep -oPm1 "(?<=<fileName>)[^<]+")
PATH_TO_FILE=$(curl -s "$JENKINS$JOB/lastBuild/api/xml" | grep -oPm1 "(?<=<relativePath>)[^<]+")
log "Downloading dist $DIST_FILE to $(pwd)"

curl -s -O "$JENKINS$JOB/lastBuild/artifact/$PATH_TO_FILE"
