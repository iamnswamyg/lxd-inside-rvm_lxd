#!/bin/bash

declare -A TARGET_WAR_APP_MAP
TARGET_WAR_APP_MAP["ufcolo1-app1"]="ufcolo1-app1-ufofs ufcolo1-app2-ufofs"
TARGET_WAR_APP_MAP["ufcolo2-app1"]="ufcolo2-app1-ufofs ufcolo2-app2-ufofs"

TARGET_APP_PORT=8283
TARGET_APP="${TARGET_WAR_APP_MAP[@]}"

TARGET_WAR_PORT=8283
TARGET_WAR="${!TARGET_WAR_APP_MAP[@]}"

TARGET_WEB_PORT=8283
{%- set app = data['application-webservers']['ufofs'] %}
TARGET_WEB="{{ app['ufcolo1']['prod'] | sort | join(' ') }} {{ app['ufcolo2']['prod'] | sort | join(' ') }}"

TARGET_DNS_PORT=8283
TARGET_DNS="aws1-dns1"

declare -A TARGET_SITE_DB_SERVER_MAP
TARGET_SITE_DB_SERVER_MAP["ufcolo1"]="ufcolo1-dbmisc1"
TARGET_SITE_DB_SERVER_MAP["ufcolo2"]="ufcolo2-dbmisc1"

TARGET_DB_SERVER="${TARGET_SITE_DB_SERVER_MAP[@]}"
TARGET_SITE="${!TARGET_SITE_DB_SERVER_MAP[@]}"

TARGET_DB_CLUSTER_NAME=ufofsprod
TARGET_DB_CLUSTER_VERSION=11

TARGET_DB_PRI_GROUPS="ufofs"
TARGET_DB_SEC_GROUPS=""

TARGET_DB_PORT=8283

# If a master database is down, add its replica to the TARGET_DB_SERVER_FORCE_PROMOTE list, this promote it without first require that it is up to date with the old master 
TARGET_DB_SERVER_FORCE_PROMOTE=""