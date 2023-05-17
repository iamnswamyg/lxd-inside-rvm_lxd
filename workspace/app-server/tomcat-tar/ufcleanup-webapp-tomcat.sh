#! /bin/sh
find /opt/tomcat/logs -type f -mtime +10 -print | xargs -r -n 1 rm -r
find /opt/tomcat/logs -type f -mtime +2 -iname "ufoweb-json-*" -print | xargs -r -n 1 rm -r
find /opt/tomcat/logs -type f -mtime +1 -empty -print  | xargs -r -n 1 rm -r
find /opt/tomcat/logs -type f -mtime +1 -print | grep -v "\.gz" | xargs -r -n 1 gzip
