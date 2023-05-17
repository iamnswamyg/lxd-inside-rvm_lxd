#! /bin/sh
find /var/log/tomcat*/ -type f -mmin +480 -regextype posix-extended -regex '^.*\.log\.[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}$' -print | xargs -r -n 1 gzip
