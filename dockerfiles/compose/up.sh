#!/bin/bash

mkdir -p ./runtime/asterisk/logs
mkdir -p ./runtime/asterisk/etc
mkdir -p ./runtime/mariadb/data
mkdir -p ./runtime/html
cd runtime/html
git clone https://github.com/rromenskyi/Asterisk-PHP-CDR .
cp ../runtime/html-config/config.php inc/config/
cd ..
cd ..

docker-compose up -d

