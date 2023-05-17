#! /bin/sh
# Martin Häggström 190314

find /var/atlassian/application-data/confluence/backups -mtime +5 | xargs -r -n 1 rm -r
