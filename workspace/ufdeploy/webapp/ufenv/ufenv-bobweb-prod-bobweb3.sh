#!/bin/bash

declare -A TARGET_WAR_APP_MAP
#TARGET_WAR_APP_MAP["ufcolo1-appdummy"]=""
#TARGET_WAR_APP_MAP["ufcolo2-appdummy"]=""

TARGET_APP_PORT=8283
TARGET_APP="${TARGET_WAR_APP_MAP[@]}"

HTDOCS_SUBSITES="admin client old"

TARGET_WAR_PORT=8283
#TARGET_WAR="${!TARGET_WAR_APP_MAP[@]}"

TARGET_WEB_PORT=8283
{%- set app = data['application-webservers']['bobweb'] %}
TARGET_WEB="ufcolo1-dmzprod3-webbob1 ufcolo2-dmzprod3-webbob1"

TARGET_DNS_PORT=8283
#TARGET_DNS="aws1-dns1"

# If a master database is down, add its replica to the TARGET_DB_SERVER_FORCE_PROMOTE list, this promote it without first require that it is up to date with the old master 
TARGET_DB_SERVER_FORCE_PROMOTE=""

LINKS="Bobweb-deploy.-Please-ignore!!-//Core"