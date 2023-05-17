#!/bin/bash

TARGET_APP_PORT=8283
TARGET_APP_WEB_PORT=8183
TARGET_APP_SHUTDOWN_PORT=8171
TARGET_APP="ufcolo1-app1-ee ufcolo1-app2-ee ufcolo2-app1-ee ufcolo2-app2-ee"

declare -A TARGET_SITE_DB_SERVER_MAP
TARGET_SITE_DB_SERVER_MAP["ufcolo1"]="ufcolo1-dbmisc1"
TARGET_SITE_DB_SERVER_MAP["ufcolo2"]="ufcolo2-dbmisc1"

TARGET_DB_SERVER="${TARGET_SITE_DB_SERVER_MAP[@]}"
TARGET_SITE="${!TARGET_SITE_DB_SERVER_MAP[@]}"

TARGET_DB_CLUSTER_NAME=hiteeprod
TARGET_DB_CLUSTER_VERSION=11

TARGET_DB_PRI_GROUPS=""
TARGET_DB_SEC_GROUPS=""

TARGET_DB_PORT=8283

# If a master database is down, add its replica to the TARGET_DB_SERVER_FORCE_PROMOTE list, this promote it without first require that it is up to date with the old master 
TARGET_DB_SERVER_FORCE_PROMOTE=""