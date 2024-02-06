#!/bin/bash

sudo apt-get -y install tar gzip

tee -a /etc/mydumpconfig.conf << END
BACKUP_PATH=/opt/backup
END

tee /usr/local/bin/backup_script.sh << END
#!/bin/bash

# Загрузка конфигурации
source /etc/mydumpconfig.conf

# Создание папки для дампов, если она еще не существует
mkdir -p \$BACKUP_PATH

# Формирование имени файла: путь/дата-время
BACKUP_FILE="\$BACKUP_PATH/\$(date +%F-%H-%M-%S)"

# Запуск tar
tar czf \$BACKUP_FILE-astconf.tar.gz -P /etc/asterisk
tar czf \$BACKUP_FILE-astvar.tar.gz -P /var/lib/asterisk
/usr/bin/mysqldump --lock-tables=false asteriskcdrdb | gzip -9 > \$BACKUP_FILE-mysqldump.gz

# Ротация: Удаление старых дампов, например, старше 14 дней
find \$BACKUP_PATH -type f -name '*.gz' -mtime +14 -delete

END

sudo chmod 755 /usr/local/bin/backup_script.sh



tee /etc/systemd/system/backup.service << END
[Unit]
Description=Daily backup service

[Service]
#Type=oneshot
Type=simple
ExecStart=/usr/local/bin/backup_script.sh

[Install]
WantedBy=multi-user.target
END

tee /etc/systemd/system/backup.timer << END
[Unit]
Description=Runs backup daily

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
END

sudo systemctl daemon-reload
sudo systemctl enable backup.timer
sudo systemctl start backup.timer
