#!/bin/bash

sudo apt-get -y install tcpdump

tee /etc/mydumpconfig.conf << END
DUMP_PATH=/opt/dump
END

tee /usr/local/bin/tcpdump_script.sh << END
#!/bin/bash

# Загрузка конфигурации
source /etc/mydumpconfig.conf

# Создание папки для дампов, если она еще не существует
mkdir -p \$DUMP_PATH

# Формирование имени файла: путь/дата-время.pcap
DUMP_FILE="\$DUMP_PATH/\$(date +%F-%H-%M-%S).pcap"

# Поиск и завершение уже запущенных процессов tcpdump
# pgrep возвращает список ID процессов, которые соответствуют шаблону поиска
for pid in \$(pgrep -f "tcpdump -s0 -n -w"); do
    if [ ! -z "\$pid" ]; then
        echo "Уже запущен tcpdump с PID \$pid, завершаем..."
        kill \$pid
        # Дайте немного времени для корректного завершения процесса
        sleep 5
    fi
done

# Запуск tcpdump
tcpdump -s0 -n -w \$DUMP_FILE port 5060

# Ротация: Удаление старых дампов, например, старше 7 дней
find \$DUMP_PATH -type f -name '*.pcap' -mtime +7 -delete

END

sudo chmod 755 /usr/local/bin/tcpdump_script.sh



tee /etc/systemd/system/tcpdump.service << END
[Unit]
Description=Daily tcpdump service

[Service]
#Type=oneshot
Type=simple
ExecStart=/usr/local/bin/tcpdump_script.sh

[Install]
WantedBy=multi-user.target
END

tee /etc/systemd/system/tcpdump.timer << END
[Unit]
Description=Runs tcpdump daily

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
END

sudo systemctl daemon-reload
sudo systemctl enable tcpdump.timer
sudo systemctl start tcpdump.timer
