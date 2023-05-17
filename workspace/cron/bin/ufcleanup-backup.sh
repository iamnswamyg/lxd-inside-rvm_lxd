#! /bin/sh
find /var/local/backup/ -maxdepth 1 \( -name "*.tar.gz" -o -name "*.dump" -o -name "*.tar.gz.gpg" -o -name "*.dump.gpg" \) -mtime +1 -print | awk '{ system("rm " $1); }'
