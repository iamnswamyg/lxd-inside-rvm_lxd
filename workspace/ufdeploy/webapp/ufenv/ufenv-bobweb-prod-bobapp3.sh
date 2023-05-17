#!/bin/bash

declare -A TARGET_WAR_APP_MAP
TARGET_WAR_APP_MAP["ufcolo1-app1"]="ufcolo1-app3-bob"
TARGET_WAR_APP_MAP["ufcolo2-app1"]="ufcolo2-app3-bob"

TARGET_APP_PORT=8283
TARGET_APP="${TARGET_WAR_APP_MAP[@]}"

HTDOCS_SUBSITES="admin client old"

TARGET_WAR_PORT=8283
TARGET_WAR="${!TARGET_WAR_APP_MAP[@]}"

TARGET_WEB_PORT=8283
{%- set app = data['application-webservers']['bobweb'] %}
#TARGET_WEB="{{ app['ufcolo1']['prod'] | sort | join(' ') }} {{ app['ufcolo2']['prod'] | sort | join(' ') }}"

TARGET_DNS_PORT=8283
#TARGET_DNS="aws1-dns1"

# If a master database is down, add its replica to the TARGET_DB_SERVER_FORCE_PROMOTE list, this promote it without first require that it is up to date with the old master 
TARGET_DB_SERVER_FORCE_PROMOTE=""

LINKS="Bobapp-deploy.-Please-ignore!!-//Core"