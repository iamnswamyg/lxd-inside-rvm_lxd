#!/bin/bash
# Echo commands and exit on error
set -xe

# Verify lets encrypt certificates
SOURCE_DIR="/etc/apache2/letsencrypt/live"
for DIR in $(ls $SOURCE_DIR); do
  openssl rsa -check -noout -in $SOURCE_DIR/$DIR/privkey.pem
  openssl verify -CAfile $SOURCE_DIR/$DIR/chain.pem $SOURCE_DIR/$DIR/fullchain.pem
done

# Reload apache config
service apache2 reload
