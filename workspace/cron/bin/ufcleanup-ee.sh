#! /bin/sh
# UfoEE
find /usr/local/ufoee/data/logs/ -type f -mtime +30 -print | xargs -r -n 1 rm -r
find /usr/local/ufoee/data/logs/ -type f -mtime +2 -print | grep -v "\.gz" | xargs -r -n 1 gzip
# HitEE
find /usr/local/hitee/data/logs/ -type f -mtime +30 -print | xargs -r -n 1 rm -r
find /usr/local/hitee/data/logs/ -type f -mtime +2 -print | grep -v "\.gz" | xargs -r -n 1 gzip
