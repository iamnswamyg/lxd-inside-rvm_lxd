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

LINKS="https://ufo-test.unifaun.se:4432/ufoweb-test-$APP_VER/"
