#! /bin/sh
echo Backing up ufwiki database
rm -r /var/backup/mediawiki/*
sudo -u postgres pg_dump -Fc wikidb > /var/backup/mediawiki/backup-wikidb.dump
date
echo Copying data
cp -r /var/www/html/mediawiki/images /var/backup/mediawiki/
date
echo Taring backup
DATE=`date +%Y%m%d`
tar -czf /var/backup/ufwikibackup.tar.gz -C /var/backup/ mediawiki
date
echo Ftping ufwiki backup
curl -T /var/backup/ufwikibackup.tar.gz ftp://colo:backup@10.13.16.55/Backup/Dagens/ufwikibackup-$DATE.tar.gz 
date
