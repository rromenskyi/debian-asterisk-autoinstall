#!/bin/bash

set -euo pipefail

CDR_INPUT_DIR="${CDR_INPUT_DIR:-/var/cdrs}"
CDR_ARCHIVE_DIR="${CDR_ARCHIVE_DIR:-/var/cdr-arch}"
CDR_TMP_DIR="${CDR_TMP_DIR:-/var/cdr-tmp}"
CDR_RETENTION_DAYS="${CDR_RETENTION_DAYS:-365}"

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
  cat > /etc/asterisk-cdr-archive.conf <<EOF
CDR_INPUT_DIR="${CDR_INPUT_DIR}"
CDR_ARCHIVE_DIR="${CDR_ARCHIVE_DIR}"
CDR_TMP_DIR="${CDR_TMP_DIR}"
CDR_RETENTION_DAYS="${CDR_RETENTION_DAYS}"
EOF
}

write_archive_script() {
  cat > /usr/local/bin/cdr_archive_script.sh <<'EOF'
#!/bin/bash

set -euo pipefail

source /etc/asterisk-cdr-archive.conf

mkdir -p "${CDR_ARCHIVE_DIR}" "${CDR_TMP_DIR}"

fmask="$(date -d "$(date +%Y-%m-01) -1 month" +%Y%m)"
archive="${CDR_ARCHIVE_DIR}/${fmask}.cdr.7z"
staged="${CDR_TMP_DIR}/${fmask}.cdr"

if [[ -e ${archive} ]]; then
  echo "archive already exists: ${archive}" >&2
  exit 0
fi

mapfile -t files < <(find "${CDR_INPUT_DIR}" -type f -name "${fmask}*")

if [[ ${#files[@]} -eq 0 ]]; then
  echo "no CDR files matching ${fmask}*" >&2
  exit 0
fi

: > "${staged}"
for f in "${files[@]}"; do
  cat "${f}" >> "${staged}"
done

7za a -mx=9 "${archive}" "${staged}" >/dev/null
7za t "${archive}" >/dev/null

rm -f "${staged}"
rm -f -- "${files[@]}"

find "${CDR_ARCHIVE_DIR}" -type f -name '*.cdr.7z' -mtime +"${CDR_RETENTION_DAYS}" -delete
EOF

  chmod 755 /usr/local/bin/cdr_archive_script.sh
}

write_systemd_units() {
  cat > /etc/systemd/system/cdr-archive.service <<'EOF'
[Unit]
Description=Monthly CDR archive

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cdr_archive_script.sh
EOF

  cat > /etc/systemd/system/cdr-archive.timer <<'EOF'
[Unit]
Description=Runs CDR archive monthly

[Timer]
OnCalendar=*-*-02 01:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

main() {
  require_root
  apt-get -y install p7zip-full findutils
  write_config
  write_archive_script
  write_systemd_units
  systemctl daemon-reload
  systemctl enable cdr-archive.timer
  systemctl start cdr-archive.timer
}

main "$@"
