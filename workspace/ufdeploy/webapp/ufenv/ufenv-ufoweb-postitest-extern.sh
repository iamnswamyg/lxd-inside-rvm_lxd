#!/bin/bash

declare -A TARGET_WAR_APP_MAP
TARGET_WAR_APP_MAP["aws1-salt1"]="aws1-testextern1-webposti1"

TARGET_APP_PORT=8284
TARGET_APP="${TARGET_WAR_APP_MAP[@]}"

TARGET_WAR_PORT=8283
TARGET_WAR="${!TARGET_WAR_APP_MAP[@]}"

TARGET_WEB_PORT=8283
TARGET_WEB="aws1-testextern1-webposti1"

#TARGET_DNS_PORT=8284
#TARGET_DNS="aws1-dns1"

LINKS="https://smartship.test.unifaun.com/ https://smartship.test.unifaun.com/ext.posti.se.se.opa"
