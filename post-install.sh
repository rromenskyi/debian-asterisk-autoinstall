#!/bin/bash
#asterisk 18-cert postinstall script on debian 12

if [ -f /usr/src/.asterisk-mysql-pass ]; then
 echo "already done"
 exit 1
fi

systemctl restart mariadb

mkdir -p /etc/asterisk/sip_config
mkdir -p /etc/asterisk/dialplan

ASTPASS=`pwgen -s 14 1`
ASTPASSCDR=`pwgen -s 14 1`

echo "CREATE USER 'asterisk'@'%' IDENTIFIED BY '$ASTPASS';" | mysql -u root
echo "CREATE USER 'asterisk'@'localhost' IDENTIFIED BY '$ASTPASS';" | mysql -u root
echo "CREATE DATABASE asterisk;" | mysql -u root
echo "GRANT ALL PRIVILEGES ON asterisk.* TO 'asterisk'@'%';" | mysql -u root
echo "GRANT ALL PRIVILEGES ON asterisk.* TO 'asterisk'@'localhost';" | mysql -u root
echo "$ASTPASS" > /usr/src/.asterisk-mysql-pass
chmod 600 /usr/src/.asterisk-mysql-pass

echo "CREATE USER 'asteriskcdr'@'%' IDENTIFIED BY '$ASTPASSCDR';" | mysql -u root
echo "CREATE USER 'asteriskcdr'@'localhost' IDENTIFIED BY '$ASTPASSCDR';" | mysql -u root
echo "CREATE DATABASE asteriskcdrdb;" | mysql -u root
echo "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO 'asteriskcdr'@'%';" | mysql -u root
echo "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO 'asteriskcdr'@'localhost';" | mysql -u root
echo "$ASTPASSCDR" > /usr/src/.asteriskcdr-mysql-pass
chmod 600 /usr/src/.asteriskcdr-mysql-pass

mysql -uasteriskcdr -p$ASTPASSCDR asteriskcdrdb -e "source cdr.sql;"

tee -a /etc/odbc.ini << END
[asterisk-cdr-connector]
Description = MySQL connection to 'asteriskcdrdb' database
Driver = MariaDB Unicode
Database = asteriskcdrdb
Server = localhost
Port = 3306
Socket = /var/run/mysqld/mysqld.sock
END


#tee -a /etc/default/asterisk << END
#AST_USER="asterisk"
#AST_GROUP="asterisk"
#END

#tee -a /etc/sysconfig/asterisk << END
#AST_USER="asterisk"
#AST_GROUP="asterisk"
#END

#groupadd asterisk
#useradd -d /var/lib/asterisk -g asterisk asterisk

chown -R asterisk:asterisk /etc/asterisk/
chown -R asterisk:asterisk /usr/lib/asterisk/
chown -R asterisk:asterisk /var/lib/asterisk/
chown -R asterisk:asterisk /var/spool/asterisk/
chown -R asterisk:asterisk /var/run/asterisk/
chown -R asterisk:asterisk /var/log/asterisk/
chown asterisk:asterisk /usr/sbin/asterisk

tee /etc/systemd/system/asterisk.service << END
[Unit]
Description=Asterisk PBX and telephony daemon.
After=network.target

[Service]
Type=simple
User=asterisk
Group=asterisk
WorkingDirectory=/usr/local/sbin
ExecStart=/usr/sbin/asterisk -f
ExecReload=/usr/sbin/asterisk -rx 'reload'
ExecStop=/usr/sbin/asterisk -rx 'shutdown now'
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable asterisk

tee -a /etc/logrotate.d/asterisk << END
/var/log/asterisk/queue_log {
        daily
        rotate 7
        missingok
        notifempty
        sharedscripts
        create 0644 asterisk asterisk
        su asterisk asterisk
        postrotate
                /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
        endscript
}

/var/log/asterisk/messages
/var/log/asterisk/security
/var/log/asterisk/full {
        daily
        rotate 62
        missingok
        compress
        notifempty
        sharedscripts
        create 0644 asterisk asterisk
        su asterisk asterisk
        postrotate
                /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
        endscript
}
END

tee -a /etc/asterisk/modules.conf << END
noload = app_voicemail_imap.so
noload = app_voicemail_odbc.so
noload=chan_iax2.so
noload=chan_alsa.so
noload=chan_audiosocket.so
noload=chan_console.so
noload=chan_mgcp.so
noload=chan_skinny.so
noload=chan_unistim.so
noload=chan_oss.so
noload=cel_pgsql.so
noload=cel_radius.so
noload=cel_sqlite3_custom.so
noload=cel_tds.so
noload=cdr_odbc.so
noload=cdr_pgsql.so
noload=cdr_radius.so
noload=cdr_sqlite3_custom.so
noload=cdr_tds.so
noload=pbx_dundi.so
noload=pbx_lua.so
END


cd /usr/lib/asterisk/modules
wget -O codec_g729.so http://asterisk.hosting.lv/bin/codec_g729-ast180-gcc4-glibc-x86_64-core2-sse4.so
wget -O codec_g723.so http://asterisk.hosting.lv/bin/codec_g723-ast180-gcc4-glibc-x86_64-core2-sse4.so
chmod 755 codec_g7*.so




