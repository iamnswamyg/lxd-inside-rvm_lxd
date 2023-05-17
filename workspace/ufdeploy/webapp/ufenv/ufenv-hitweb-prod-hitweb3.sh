#!/bin/bash

declare -A TARGET_WAR_APP_MAP
TARGET_WAR_APP_MAP["ufcolo1-appdummy"]=""
TARGET_WAR_APP_MAP["ufcolo2-appdummy"]=""

TARGET_APP_PORT=8283
TARGET_APP="${TARGET_WAR_APP_MAP[@]}"

TARGET_WAR_PORT=8283
#TARGET_WAR="${!TARGET_WAR_APP_MAP[@]}"

TARGET_WEB_PORT=8283
{%- set app = data['application-webservers']['hitweb'] %}
TARGET_WEB="ufcolo1-dmzprod3-webhit1 ufcolo2-dmzprod3-webhit1"

TARGET_DNS_PORT=8283
#TARGET_DNS="aws1-dns1"

NO_LAYOUTS=YES

# If a master database is down, add its replica to the TARGET_DB_SERVER_FORCE_PROMOTE list, this promote it without first require that it is up to date with the old master 
TARGET_DB_SERVER_FORCE_PROMOTE=""

LINKS="Super hitweb deploy. Please ignore!! //Core "
