#!/bin/bash

declare -A TARGET_WAR_APP_MAP
TARGET_WAR_APP_MAP["ufcolo1-app1"]="ufcolo1-app1-ufo ufcolo1-app2-ufo ufcolo1-app3-ufo"
TARGET_WAR_APP_MAP["ufcolo2-app1"]="ufcolo2-app1-ufo ufcolo2-app2-ufo ufcolo2-app3-ufo"

TARGET_APP_PORT=8283
# TARGET_APP contains all *values* in TARGET_WAR_APP_MAP, i.e. all containers to deploy to.
TARGET_APP="${TARGET_WAR_APP_MAP[@]}"

TARGET_WAR_PORT=8283
# TARGET_WAR contains all *keys* in TARGET_WAR_APP_MAP, i.e. hosts receiving WAR files
# and running curl commands for deploying them.
TARGET_WAR="${!TARGET_WAR_APP_MAP[@]}"

TARGET_WEB_PORT=8283
{%- set app = data['application-webservers']['ufoweb'] %}
TARGET_WEB="{{ app['ufcolo1']['prod'] | sort | join(' ') }} {{ app['ufcolo2']['prod'] | sort | join(' ') }}"

TARGET_DNS_PORT=8283
TARGET_DNS="aws1-dns1"

declare -A TARGET_SITE_DB_SERVER_MAP
# <server-name> (ufcolo2-dbufo1) or <server_name>:<synch_port>:<cluster_name>:<cluster_version> (ufcolo2-dbufo1:8283:dbmaster:9.4)
TARGET_SITE_DB_SERVER_MAP["ufcolo1"]="ufcolo1-dbufo1 ufcolo1-dbmisc1"
TARGET_SITE_DB_SERVER_MAP["ufcolo2"]="ufcolo2-dbufo1 ufcolo2-dbmisc1"

TARGET_DB_SERVER="${TARGET_SITE_DB_SERVER_MAP[@]}"
TARGET_SITE="${!TARGET_SITE_DB_SERVER_MAP[@]}"

TARGET_DB_CLUSTER_NAME=ufoprod
TARGET_DB_CLUSTER_VERSION=11

TARGET_DB_PRI_GROUPS="ufo20"
TARGET_DB_SEC_GROUPS="ufo21:ufo22:ufo23:ufo24:ufohist"

TARGET_DB_PORT=8283

# If a master database is down, add its replica to the TARGET_DB_SERVER_FORCE_PROMOTE list, this promote it without first require that it is up to date with the old master 
TARGET_DB_SERVER_FORCE_PROMOTE=""

# APP_VER is set in ufdeploy.sh and taken from the filename of the dist.tar
LINKS="https://ufcolo1-dmzprod1-webuo1-prod-$APP_VER.test.unifaun.com:4431"
