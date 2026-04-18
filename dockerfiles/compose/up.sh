#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
RUNTIME_DIR="${SCRIPT_DIR}/runtime"
HTML_DIR="${RUNTIME_DIR}/html"
HTML_CONFIG="${RUNTIME_DIR}/html-config/config.php"

log() {
  printf '%s\n' "$*"
}

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
    return
  fi

  docker-compose "$@"
}

prepare_runtime_dirs() {
  mkdir -p \
    "${RUNTIME_DIR}/asterisk/etc" \
    "${RUNTIME_DIR}/asterisk/logs" \
    "${RUNTIME_DIR}/html" \
    "${RUNTIME_DIR}/mariadb/data"
}

sync_cdr_ui() {
  if [[ -d "${HTML_DIR}/.git" ]]; then
    log "updating Asterisk-PHP-CDR checkout"
    git -C "${HTML_DIR}" pull --ff-only
  elif [[ -z "$(find "${HTML_DIR}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    log "cloning Asterisk-PHP-CDR"
    git clone https://github.com/rromenskyi/Asterisk-PHP-CDR "${HTML_DIR}"
  else
    log "runtime/html already contains files; leaving existing contents in place"
  fi

  if [[ -f "${HTML_CONFIG}" && -d "${HTML_DIR}/inc/config" ]]; then
    cp "${HTML_CONFIG}" "${HTML_DIR}/inc/config/config.php"
  fi
}

main() {
  prepare_runtime_dirs
  sync_cdr_ui
  cd "${SCRIPT_DIR}"
  compose up -d
}

main "$@"
