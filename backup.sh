#!/bin/bash

set -euo pipefail

BACKUP_PATH="${BACKUP_PATH:-/opt/backup}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"

log() {
  printf '%s\n' "$*"
}

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    log "run this script as root or via sudo"
    exit 1
  fi
}

write_config() {
  cat > /etc/asterisk-backup.conf <<EOF
BACKUP_PATH="${BACKUP_PATH}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS}"
EOF
}

write_backup_script() {
  cat > /usr/local/bin/backup_script.sh <<'EOF'
#!/bin/bash

set -euo pipefail

source /etc/asterisk-backup.conf

mkdir -p "${BACKUP_PATH}"

timestamp="$(date +%F-%H-%M-%S)"
backup_prefix="${BACKUP_PATH}/${timestamp}"

tar czf "${backup_prefix}-astconf.tar.gz" -P /etc/asterisk
tar czf "${backup_prefix}-astvar.tar.gz" -P /var/lib/asterisk
/usr/bin/mysqldump --lock-tables=false asteriskcdrdb | gzip -9 > "${backup_prefix}-mysqldump.gz"

find "${BACKUP_PATH}" -type f -name '*.gz' -mtime +"${BACKUP_RETENTION_DAYS}" -delete
EOF

  chmod 755 /usr/local/bin/backup_script.sh
}

write_systemd_units() {
  cat > /etc/systemd/system/backup.service <<'EOF'
[Unit]
Description=Daily backup service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup_script.sh
EOF

  cat > /etc/systemd/system/backup.timer <<'EOF'
[Unit]
Description=Runs backup daily

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

main() {
  require_root
  apt-get -y install tar gzip
  write_config
  write_backup_script
  write_systemd_units
  systemctl daemon-reload
  systemctl enable backup.timer
  systemctl start backup.timer
}

main "$@"
