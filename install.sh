#!/bin/sh
# Install Asterisk Certified 18 and supporting tooling on Debian 12.

set -eu

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"

ASTERISK_TIMEZONE="${ASTERISK_TIMEZONE:-UTC}"
BUILD_JOBS="${BUILD_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

SRC_DIR="/usr/src"
ASTERISK_ARCHIVE_URL="https://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-current.tar.gz"
ASTERISK_MD5_URL="https://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-current.md5"
ASTERISK_ARCHIVE="${SRC_DIR}/asterisk-certified-current.tar.gz"
ASTERISK_MD5_FILE="${SRC_DIR}/asterisk-certified-current.md5"
ASTERISK_SOURCE_LINK="${SRC_DIR}/asterisk-certified"
PJPROJECT_DIR="${SRC_DIR}/pjproject"
SNGREP_DIR="${SRC_DIR}/sngrep"

log() {
  printf '%s\n' "$*"
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log "run this script as root or via sudo"
    exit 1
  fi
}

install_packages() {
  log "installing Debian packages"
  apt-get update
  apt-get -y install \
    mc \
    fail2ban \
    docker.io \
    libedit-dev \
    git \
    curl \
    wget \
    libnewt-dev \
    libssl-dev \
    libncurses5-dev \
    subversion \
    libsqlite3-dev \
    build-essential \
    libjansson-dev \
    libxml2-dev \
    uuid-dev \
    autoconf \
    libpcap-dev \
    libxml2-utils \
    odbc-mariadb \
    mariadb-server \
    pwgen \
    libmariadb-dev \
    unixodbc-dev \
    p7zip-full
}

configure_limits() {
  log "writing system limits for Asterisk"
  mkdir -p /etc/security/limits.d
  cat > /etc/security/limits.d/asterisk.conf <<'EOF'
root            soft    nofile          16384
root            hard    nofile          65535
asterisk        soft    nofile          16384
asterisk        hard    nofile          65535
EOF
}

configure_fail2ban() {
  log "configuring fail2ban"
  mkdir -p /var/run/fail2ban
  cat > /etc/fail2ban/jail.d/defaults-debian.conf <<'EOF'
[sshd]
backend=systemd
enabled=true

[asterisk]
enabled  = true
port     = 5060,5061
action   = %(action_mwl)s
filter   = asterisk
logpath  = /var/log/asterisk/full
maxretry = 5
bantime  = 600
findtime = 600
EOF
  systemctl restart fail2ban
}

configure_timezone() {
  log "setting timezone to ${ASTERISK_TIMEZONE}"
  timedatectl set-timezone "${ASTERISK_TIMEZONE}"
}

download_asterisk_source() {
  log "downloading Asterisk Certified sources"
  mkdir -p "${SRC_DIR}"
  cd "${SRC_DIR}"
  wget -cq -O "${ASTERISK_ARCHIVE}" "${ASTERISK_ARCHIVE_URL}"
  wget -cq -O "${ASTERISK_MD5_FILE}" "${ASTERISK_MD5_URL}"

  asterisk_dir="$(awk '{print $2}' "${ASTERISK_MD5_FILE}" | sed 's/\.tar\.gz$//')"
  ln -sfn "${asterisk_dir}" "${ASTERISK_SOURCE_LINK}"
  sed -i 's/asterisk-.*\.tar\.gz/asterisk-certified-current.tar.gz/' "${ASTERISK_MD5_FILE}"

  md5sum --ignore-missing -c "${ASTERISK_MD5_FILE}"

  if [ ! -d "${SRC_DIR}/${asterisk_dir}" ]; then
    log "extracting Asterisk archive"
    tar -zxf "${ASTERISK_ARCHIVE}"
  fi

  rm -f "${ASTERISK_SOURCE_LINK}/menuselect.makeopts"
}

ensure_git_checkout() {
  target_dir="$1"
  repo_url="$2"

  if [ ! -d "${target_dir}/.git" ]; then
    log "cloning $(basename "${target_dir}")"
    git clone "${repo_url}" "${target_dir}"
    return
  fi

  log "updating $(basename "${target_dir}")"
  (
    cd "${target_dir}"
    git pull --ff-only
  )
}

build_pjproject() {
  ensure_git_checkout "${PJPROJECT_DIR}" "https://github.com/asterisk/pjproject"

  if [ -f /usr/local/lib/libpjmedia-audiodev.so.2 ]; then
    log "pjproject already installed"
    return
  fi

  log "building pjproject"
  (
    cd "${PJPROJECT_DIR}"
    ./configure \
      --prefix=/usr/local \
      --enable-shared \
      --disable-sound \
      --disable-resample \
      --disable-video \
      --disable-opencore-amr
    make dep
    make -j"${BUILD_JOBS}"
    make install
  )
}

build_sngrep() {
  ensure_git_checkout "${SNGREP_DIR}" "https://github.com/irontec/sngrep"

  if [ -f /usr/local/bin/sngrep ]; then
    log "sngrep already installed"
    return
  fi

  log "building sngrep"
  (
    cd "${SNGREP_DIR}"
    ./bootstrap.sh
    ./configure --prefix=/usr/local
    make -j"${BUILD_JOBS}"
    make install
  )
}

install_asterisk() {
  if [ -f /usr/sbin/asterisk ]; then
    log "asterisk already installed"
    return
  fi

  log "building and installing Asterisk"
  (
    cd "${ASTERISK_SOURCE_LINK}"
    contrib/scripts/get_mp3_source.sh
    ./configure
    make -j"${BUILD_JOBS}"
    make samples
    make config
    make install
  )
}

ensure_asterisk_group() {
  if getent group asterisk >/dev/null 2>&1; then
    log "group asterisk already exists"
    return
  fi

  log "creating group asterisk"
  addgroup asterisk
}

ensure_asterisk_user() {
  if id asterisk >/dev/null 2>&1; then
    log "user asterisk already exists"
    return
  fi

  log "creating user asterisk"
  useradd asterisk -d /var/lib/asterisk -g asterisk -s /usr/sbin/nologin -M
}

main() {
  require_root
  install_packages
  configure_limits
  configure_fail2ban
  configure_timezone
  download_asterisk_source
  build_pjproject
  build_sngrep
  install_asterisk
  ensure_asterisk_group
  ensure_asterisk_user
}

main "$@"
