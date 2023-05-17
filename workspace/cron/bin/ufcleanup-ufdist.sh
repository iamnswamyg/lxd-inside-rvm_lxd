#!/bin/bash
# Program to remove files from deploys to testservers under /root/ufdist

for DIR in $(find /root/ufdist/ -maxdepth 1 -type d -name '*test')
do
  ls -1 $DIR | sort | head -n -5 | xargs -d '\n' -n 1 -I{} rm "$DIR/{}"
done

for DIR in $(find /root/ufdist/ -maxdepth 1 -mindepth 1 -type d)
do
  echo $DIR
  # Remove files thats older than 30 days and not one of the last 10 deploys
  comm -12 <(ls -1 $DIR | grep -E "^$(basename $DIR)-[0-9]{12}-[a-z]+\.dist.tar$" | sort | head -n -10) <(find $DIR -maxdepth 1 -mindepth 1 -type f -mtime +30 | xargs -rn 1 basename | grep -E "^$(basename $DIR)-[0-9]{12}-[a-z]+\.dist.tar$" | sort) | xargs -r -n 1 -I{} rm -v "$DIR/{}" 
done
