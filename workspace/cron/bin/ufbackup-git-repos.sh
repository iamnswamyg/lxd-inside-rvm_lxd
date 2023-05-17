#!/bin/bash
echo "Deleting old repos"
find /var/backup/git -type f -mmin +5760 -print | xargs -r -n 1 rm -vr
date
echo Backing up git repos
for REPO in $(echo /srv/git/*.git); do
    REPO_NAME=$(basename "$REPO" .git)
	/usr/local/bin/ufbackup-git-repo.sh "$REPO_NAME"
done;
echo Backup done!
