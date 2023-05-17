#! /bin/sh
SOURCE_DIR=/var/webapp/orders
TARGET_DIR={{ target_dir }}
# Move files
for SOURCE in $(find "$SOURCE_DIR" -mindepth 2 -maxdepth 2 -type f -mmin +10 -print)
do
  FILE=$(basename "$SOURCE")
  DIR=$(basename $(dirname "$SOURCE"))
  if [ ! -d "$TARGET_DIR/$DIR" ]; then
    echo mkdir "$TARGET_DIR/$DIR"
    mkdir "$TARGET_DIR/$DIR"
  fi
  echo mv "$SOURCE" "$TARGET_DIR/$DIR/$FILE"
  mv "$SOURCE" "$TARGET_DIR/$DIR/$FILE"
done
# Remove empty directories
find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +1 -empty -print | xargs -r -n 1 rmdir
