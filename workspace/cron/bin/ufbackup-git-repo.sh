#!/bin/bash

REPO_NAME=$1
REPO_PATH=/srv/git/${REPO_NAME}.git

date
DATE=$(date +%Y%m%d)
echo Backing up git repo $REPO_PATH
echo Creating bundle /var/backup/git/$REPO_NAME-$DATE.bundle
cd $REPO_PATH
git bundle create /var/backup/git/$REPO_NAME-$DATE.bundle --all
date
echo Ftping git backup
curl -T /var/backup/git/$REPO_NAME-$DATE.bundle ftp://colo:backup@10.13.16.55/Backup/Dagens/$REPO_NAME-$DATE.bundle 
date
