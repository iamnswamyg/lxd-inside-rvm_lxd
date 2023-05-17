#! /bin/bash
set -xe
TARGET_DIR={{ target_dir }}
EMPTY_DIR=/tmp/emptydir/
DATE=$(date --date="-30 days" +%Y%m%d)

# Abort if we did not get numeric date
if ! [[ "$DATE" =~ ^[0-9]{8}$ ]]
then
  echo Invalid date $DATE
  exit 1
fi

mkdir $EMPTY_DIR

for DIR in $(ls $TARGET_DIR)
do
  if [[ "$DIR" =~ ^[0-9]{8,10}$ && "$DIR" < "$DATE" ]]
  then
    rsync -a --delete $EMPTY_DIR "$TARGET_DIR/$DIR"
    rm -r "$TARGET_DIR/$DIR"
  fi
done

rm -rf $EMPTY_DIR
