#!/bin/bash

declare -A TARGET_WAR_APP_MAP
TARGET_WAR_APP_MAP["ufoffice-salt1"]="ufoffice-test1"

TARGET_APP_PORT=8284
TARGET_APP="${TARGET_WAR_APP_MAP[@]}"

TARGET_WAR_PORT=8283
TARGET_WAR="${!TARGET_WAR_APP_MAP[@]}"

TARGET_WEB_PORT=8283
TARGET_WEB="ufoffice-test1"

TARGET_DNS_PORT=8284
TARGET_DNS="aws1-dns1"

declare -A TARGET_SITE_DB_SERVER_MAP
TARGET_SITE_DB_SERVER_MAP["site1"]="test1"
TARGET_SITE_DB_SERVER_MAP["site2"]="test2"

TARGET_DB_SERVER="${TARGET_SITE_DB_SERVER_MAP[@]}"
TARGET_SITE="${!TARGET_SITE_DB_SERVER_MAP[@]}"

TARGET_DB_CLUSTER_NAME=ufofstest
TARGET_DB_CLUSTER_VERSION=9.4

TARGET_DB_PRI_GROUPS="ufofs"
TARGET_DB_SEC_GROUPS=""

TARGET_DB_PORT=8283

# If a master database is down, add its replica to the TARGET_DB_SERVER_FORCE_PROMOTE list, this promote it without first require that it is up to date with the old master 
TARGET_DB_SERVER_FORCE_PROMOTE=""