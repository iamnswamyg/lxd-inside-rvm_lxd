#! /bin/sh
find /var/webapp/orders -type d -mtime +30 -print | xargs -r -n 1 rm -r
