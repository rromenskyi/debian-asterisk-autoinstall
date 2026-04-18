#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ASTERISK_DB_PASSWORD_FILE="/usr/src/.asterisk-mysql-pass"
ASTERISK_CDR_DB_PASSWORD_FILE="/usr/src/.asteriskcdr-mysql-pass"

log() {
  printf '%s\n' "$*"
}

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    log "run this script as root or via sudo"
    exit 1
  fi
}

already_configured() {
  [[ -f "${ASTERISK_DB_PASSWORD_FILE}" && -f "${ASTERISK_CDR_DB_PASSWORD_FILE}" ]]
}

mysql_root() {
  mysql -u root "$@"
}

write_secret_file() {
  local target_file="$1"
  local secret="$2"

  printf '%s\n' "${secret}" > "${target_file}"
  chmod 600 "${target_file}"
}

prepare_directories() {
  install -d \
    /etc/asterisk \
    /etc/asterisk/dialplan \
    /etc/asterisk/sip_config \
    /usr/lib/asterisk/modules \
    /var/lib/asterisk \
    /var/log/asterisk \
    /var/run/asterisk \
    /var/spool/asterisk
}

configure_databases() {
  local astpass="$1"
  local astpasscdr="$2"

  systemctl restart mariadb

  mysql_root <<SQL
CREATE DATABASE IF NOT EXISTS asterisk;
CREATE USER IF NOT EXISTS 'asterisk'@'%' IDENTIFIED BY '${astpass}';
CREATE USER IF NOT EXISTS 'asterisk'@'localhost' IDENTIFIED BY '${astpass}';
GRANT ALL PRIVILEGES ON asterisk.* TO 'asterisk'@'%';
GRANT ALL PRIVILEGES ON asterisk.* TO 'asterisk'@'localhost';

CREATE DATABASE IF NOT EXISTS asteriskcdrdb;
CREATE USER IF NOT EXISTS 'asteriskcdr'@'%' IDENTIFIED BY '${astpasscdr}';
CREATE USER IF NOT EXISTS 'asteriskcdr'@'localhost' IDENTIFIED BY '${astpasscdr}';
GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO 'asteriskcdr'@'%';
GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO 'asteriskcdr'@'localhost';
FLUSH PRIVILEGES;
SQL

  write_secret_file "${ASTERISK_DB_PASSWORD_FILE}" "${astpass}"
  write_secret_file "${ASTERISK_CDR_DB_PASSWORD_FILE}" "${astpasscdr}"
  mysql -u asteriskcdr -p"${astpasscdr}" asteriskcdrdb < "${SCRIPT_DIR}/cdr.sql"
}

configure_odbc() {
  if grep -q '^\[asterisk-cdr-connector\]$' /etc/odbc.ini 2>/dev/null; then
    return
  fi

  if [[ -s /etc/odbc.ini ]]; then
    printf '\n' >> /etc/odbc.ini
  fi

  cat >> /etc/odbc.ini <<'EOF'
[asterisk-cdr-connector]
Description = MySQL connection to 'asteriskcdrdb' database
Driver = MariaDB Unicode
Database = asteriskcdrdb
Server = localhost
Port = 3306
Socket = /var/run/mysqld/mysqld.sock
EOF
}

set_ownership() {
  local path

  for path in \
    /etc/asterisk \
    /usr/lib/asterisk \
    /var/lib/asterisk \
    /var/spool/asterisk \
    /var/run/asterisk \
    /var/log/asterisk; do
    chown -R asterisk:asterisk "${path}"
  done

  if [[ -e /usr/sbin/asterisk ]]; then
    chown asterisk:asterisk /usr/sbin/asterisk
  fi
}

write_service_unit() {
  cat > /etc/systemd/system/asterisk.service <<'EOF'
[Unit]
Description=Asterisk PBX and telephony daemon
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
EOF

  systemctl daemon-reload
  systemctl enable asterisk
}

write_logrotate_config() {
  cat > /etc/logrotate.d/asterisk <<'EOF'
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
EOF
}

append_modules_block() {
  if grep -q 'app_voicemail_imap.so' /etc/asterisk/modules.conf 2>/dev/null; then
    return
  fi

  if [[ -s /etc/asterisk/modules.conf ]]; then
    printf '\n' >> /etc/asterisk/modules.conf
  fi

  cat >> /etc/asterisk/modules.conf <<'EOF'
noload = app_voicemail_imap.so
noload = app_voicemail_odbc.so
noload = chan_iax2.so
noload = chan_alsa.so
noload = chan_audiosocket.so
noload = chan_console.so
noload = chan_mgcp.so
noload = chan_skinny.so
noload = chan_unistim.so
noload = chan_oss.so
noload = cel_pgsql.so
noload = cel_radius.so
noload = cel_sqlite3_custom.so
noload = cel_tds.so
noload = cdr_odbc.so
noload = cdr_pgsql.so
noload = cdr_radius.so
noload = cdr_sqlite3_custom.so
noload = cdr_tds.so
noload = pbx_dundi.so
noload = pbx_lua.so
EOF
}

install_optional_codecs() {
  cd /usr/lib/asterisk/modules

  if wget -O codec_g729.so http://asterisk.hosting.lv/bin/codec_g729-ast180-gcc4-glibc-x86_64-core2-sse4.so && \
     wget -O codec_g723.so http://asterisk.hosting.lv/bin/codec_g723-ast180-gcc4-glibc-x86_64-core2-sse4.so; then
    chmod 755 codec_g7*.so
    return
  fi

  log "optional codec download failed; continuing without third-party codecs"
}

main() {
  local astpass
  local astpasscdr

  require_root

  if already_configured; then
    log "post-install already completed"
    exit 0
  fi

  prepare_directories

  astpass="$(pwgen -s 14 1)"
  astpasscdr="$(pwgen -s 14 1)"

  configure_databases "${astpass}" "${astpasscdr}"
  configure_odbc
  set_ownership
  write_service_unit
  write_logrotate_config
  append_modules_block
  install_optional_codecs
}

main "$@"
