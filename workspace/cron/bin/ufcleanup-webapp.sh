#! /bin/sh
find /var/log/tomcat7/ -type f -mtime +10 -print | xargs -r -n 1 rm -r
find /var/log/tomcat7/ -type f -mtime +2 -iname "ufoweb-json-*" -print | xargs -r -n 1 rm -r
find /var/log/tomcat7/ -type f -mtime +1 -empty -print  | xargs -r -n 1 rm -r
find /var/log/tomcat7/ -type f -mtime +1 -print | grep -v "\.gz" | xargs -r -n 1 gzip
find /tmp/tomcat7-tomcat7-tmp/ -type f -mtime +10 -print | xargs -r -n 1 rm -r
