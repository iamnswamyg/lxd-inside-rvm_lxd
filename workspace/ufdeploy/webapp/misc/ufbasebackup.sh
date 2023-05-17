#!/bin/bash
NAME=$1
HOST=$2
PORT=$3

if [ -z "$NAME" ] || [ -z "$HOST" ] || [ -z "$PORT" ]; then
  echo "ufbasebackup <cluster name> <host> <port>"
  exit 0
fi

echo "Name: $NAME"
echo "Host: $HOST"
echo "Port: $PORT"

echo "Starting backup"
date
pg_basebackup -D ${NAME}.new -Fp -c fast -l basebackup2 -x -v -P -U replusr -h $HOST -p $PORT
date
read -r -p "Continue? [y/N] " RESPONSE
if [[ $RESPONSE =~ ^([yY])$ ]]; then
  echo "Renaming ${NAME} to ${NAME}.old"
  mv ${NAME} ${NAME}.old
  echo "Copy recovery.template"
  cp ${NAME}.old/recovery.template ${NAME}.new/recovery.template
  echo "Copy recovery.template to recovery.conf"
  cp ${NAME}.new/recovery.template ${NAME}.new/recovery.conf
  echo "Renaming ${NAME}.new to ${NAME}"
  mv ${NAME}.new ${NAME}
  echo "Chaning owner of ${NAME} to postgres"
  chown postgres:postgres -R ${NAME}
  echo "Done"
else
  exit 0
fi

