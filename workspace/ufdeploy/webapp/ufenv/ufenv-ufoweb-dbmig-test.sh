#!/bin/bash

declare -A TARGET_WAR_APP_MAP
TARGET_WAR_APP_MAP["ufoffice-salt1"]="ufoffice-test3-lars"

#TARGET_APP_PORT=8283
TARGET_APP_PORT=8284
TARGET_APP="${TARGET_WAR_APP_MAP[@]}"

TARGET_WAR_PORT=8283
TARGET_WAR="${!TARGET_WAR_APP_MAP[@]}"

TARGET_WEB_PORT=8283
TARGET_WEB="ufoffice-test3-lars"

#TARGET_DNS_PORT=8283
#TARGET_DNS="aws1-dns1"

declare -A TARGET_SITE_DB_SERVER_MAP
TARGET_SITE_DB_SERVER_MAP["ufcolo1"]="ufcolo1-dbufo1"
TARGET_SITE_DB_SERVER_MAP["ufcolo2"]="ufcolo2-dbufo1"

TARGET_DB_SERVER="${TARGET_SITE_DB_SERVER_MAP[@]}"
TARGET_SITE="${!TARGET_SITE_DB_SERVER_MAP[@]}"

TARGET_DB_CLUSTER_NAME=ufoprod
TARGET_DB_CLUSTER_VERSION=11

TARGET_DB_PRI_GROUPS="ufo20"
TARGET_DB_SEC_GROUPS="ufo21:ufo22:ufo23:ufo24"

TARGET_DB_PORT=8283

# If a master database is down, add its replica to the TARGET_DB_SERVER_FORCE_PROMOTE list, this promote it without first require that it is up to date with the old master 
TARGET_DB_SERVER_FORCE_PROMOTE=""
