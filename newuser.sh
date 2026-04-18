#!/bin/bash

set -euo pipefail

USERNAME='username'
GROUPNAME='username'
SSH_PUBLIC_KEY='ssh-rsa '

log() {
  printf '%s\n' "$*"
}

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    log "run this script as root"
    exit 1
  fi
}

validate_placeholders() {
  if [[ "${USERNAME}" == "username" ]]; then
    log "edit USERNAME before running this script"
    exit 1
  fi

  if [[ -z "${SSH_PUBLIC_KEY}" || "${SSH_PUBLIC_KEY}" == "ssh-rsa " ]]; then
    log "edit SSH_PUBLIC_KEY before running this script"
    exit 1
  fi
}

ensure_group() {
  if [[ -z "${GROUPNAME}" ]]; then
    return
  fi

  if getent group "${GROUPNAME}" >/dev/null; then
    return
  fi

  log "creating group ${GROUPNAME}"
  groupadd "${GROUPNAME}"
}

ensure_user() {
  if id "${USERNAME}" >/dev/null 2>&1; then
    log "user ${USERNAME} already exists"
    return
  fi

  log "creating user ${USERNAME}"
  if [[ -n "${GROUPNAME}" ]]; then
    adduser --disabled-password --gecos "" --ingroup "${GROUPNAME}" "${USERNAME}"
    return
  fi

  adduser --disabled-password --gecos "" "${USERNAME}"
}

ensure_sudo_membership() {
  if id -nG "${USERNAME}" | tr ' ' '\n' | grep -qx 'sudo'; then
    return
  fi

  usermod -a -G sudo "${USERNAME}"
  log "${USERNAME} added to sudo group"
}

install_authorized_key() {
  local user_home
  local user_group

  user_home="$(getent passwd "${USERNAME}" | cut -d: -f6)"
  user_group="$(id -gn "${USERNAME}")"
  install -d -m 700 -o "${USERNAME}" -g "${user_group}" "${user_home}/.ssh"
  printf '%s\n' "${SSH_PUBLIC_KEY}" > "${user_home}/.ssh/authorized_keys"
  chown "${USERNAME}:${user_group}" "${user_home}/.ssh/authorized_keys"
  chmod 600 "${user_home}/.ssh/authorized_keys"
}

main() {
  require_root
  validate_placeholders
  ensure_group
  ensure_user
  ensure_sudo_membership
  install_authorized_key
  log "user ${USERNAME} has been successfully set up"
}

main "$@"
