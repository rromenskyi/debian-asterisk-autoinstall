#!/bin/bash

mkdir -p ./asterisk/logs
mkdir -p ./asterisk/etc
mkdir -p ./mariadb/data
mkdir -p ./html
cd html
git clone https://github.com/rromenskyi/Asterisk-PHP-CDR .
cp ../html-config/config.php inc/config/
cd ..

docker-compose up -d

