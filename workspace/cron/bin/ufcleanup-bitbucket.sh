#! /bin/sh

find /opt/atlassian/bitbucket/backup/backups -mtime +5 | xargs -r -n 1 rm -r
