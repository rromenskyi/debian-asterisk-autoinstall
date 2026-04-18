#!/bin/bash

set -euo pipefail

DUMP_PATH="${DUMP_PATH:-/opt/dump}"
CAPTURE_DURATION="${CAPTURE_DURATION:-86400}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
TCPDUMP_FILTER="${TCPDUMP_FILTER:-port 5060}"

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
  cat > /etc/asterisk-tcpdump.conf <<EOF
DUMP_PATH="${DUMP_PATH}"
CAPTURE_DURATION="${CAPTURE_DURATION}"
RETENTION_DAYS="${RETENTION_DAYS}"
TCPDUMP_FILTER="${TCPDUMP_FILTER}"
EOF
}

write_capture_script() {
  cat > /usr/local/bin/tcpdump_script.sh <<'EOF'
#!/bin/bash

set -euo pipefail

source /etc/asterisk-tcpdump.conf

mkdir -p "${DUMP_PATH}"

timestamp="$(date +%F-%H-%M-%S)"
dump_file="${DUMP_PATH}/${timestamp}.pcap"

set +e
timeout "${CAPTURE_DURATION}" tcpdump -s0 -n -w "${dump_file}" ${TCPDUMP_FILTER}
status=$?
set -e

if [[ ${status} -ne 0 && ${status} -ne 124 ]]; then
  exit "${status}"
fi

find "${DUMP_PATH}" -type f -name '*.pcap' -mtime +"${RETENTION_DAYS}" -delete
EOF

  chmod 755 /usr/local/bin/tcpdump_script.sh
}

write_systemd_units() {
  cat > /etc/systemd/system/tcpdump.service <<'EOF'
[Unit]
Description=Scheduled SIP tcpdump capture

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tcpdump_script.sh
EOF

  cat > /etc/systemd/system/tcpdump.timer <<'EOF'
[Unit]
Description=Runs tcpdump daily

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

main() {
  require_root
  apt-get -y install tcpdump
  write_config
  write_capture_script
  write_systemd_units
  systemctl daemon-reload
  systemctl enable tcpdump.timer
  systemctl start tcpdump.timer
}

main "$@"
