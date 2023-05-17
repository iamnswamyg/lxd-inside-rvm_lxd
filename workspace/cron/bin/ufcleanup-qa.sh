#! /bin/sh
find /var/log/tomcat7/ -type f -mtime +10 -print | xargs -r -n 1 rm -r
