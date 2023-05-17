#!/bin/bash

SCRIPT=$1
APP_NAME=$2
DIST_NAME=$3
LINKS=$4

if [[ -z $APP_NAME ]] || [[ -z $DIST_NAME ]]; then
  echo "Can't run notify script due to missing arguments"
  exit 1
fi

if [[ -z "$SUDO_USER" ]]; then
  USER="ufdeploy"
else
  USER=$SUDO_USER
fi

if [[ "$SCRIPT" =~ ufdeploy* ]]; then
  TEXT=", \"text\": \"I just *deployed* a new version of $APP_NAME: *$DIST_NAME*\""
  if [[ ! -z "$LINKS" ]]; then
    ATTACHMENT=", \"attachments\": [{\"title\": \"$LINKS\", \"title_link\": \"$LINKS\", \"color\": \"#7CD197\"}]"
  fi
elif [[ "$SCRIPT" =~ undeploy ]]; then
  TEXT=", \"text\": \"I just *undeployed* an old version of $APP_NAME: *$DIST_NAME*\""
elif [[ "$SCRIPT" =~ ufwarmup ]]; then
  TEXT=", \"text\": \"I just run *warmup* on $APP_NAME for version: *$DIST_NAME*\""
else
  TEXT=", \"text\": \"I just *activated* a new version of $APP_NAME: *$DIST_NAME*\""
fi

curl -s -X POST --data-urlencode "payload={\"username\": \"$USER\", \"icon_emoji\": \":bomb:\"$TEXT$ATTACHMENT}" https://hooks.slack.com/services/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 > /dev/null
