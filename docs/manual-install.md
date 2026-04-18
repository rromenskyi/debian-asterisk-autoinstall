# Manual Install

This is the intended host-based installation flow for a fresh Debian 12 system.

## Prerequisites

- Debian 12 host
- Root shell or passwordless `sudo`
- Internet access for Debian packages, Asterisk downloads, and source builds
- Enough CPU/RAM to build pjproject, sngrep, and Asterisk from source

## Install Sequence

1. Clone the repository and enter it.

   ```bash
   git clone https://github.com/rromenskyi/debian-asterisk-autoinstall.git
   cd debian-asterisk-autoinstall
   ```

2. Run the base installer.

   ```bash
   sudo ./install.sh
   ```

   What it does:

   - Installs Debian packages and build dependencies
   - Configures `fail2ban` for SSH and Asterisk logs
   - Sets timezone to `UTC`
   - Downloads and verifies Asterisk Certified source
   - Builds `pjproject`
   - Builds `sngrep`
   - Compiles and installs Asterisk if not already present
   - Creates the `asterisk` user/group when needed

3. Run the post-install step.

   ```bash
   sudo ./post-install.sh
   ```

   What it does:

   - Restarts MariaDB
   - Creates `asterisk` and `asteriskcdr` database users
   - Creates `asterisk` and `asteriskcdrdb` databases
   - Imports the bundled [`cdr.sql`](../cdr.sql)
   - Writes ODBC, systemd, and logrotate configuration
   - Sets ownership on Asterisk directories
   - Downloads third-party codec modules

## Expected Artifacts

- `/usr/src/.asterisk-mysql-pass`
- `/usr/src/.asteriskcdr-mysql-pass`
- `/etc/systemd/system/asterisk.service`
- `/etc/logrotate.d/asterisk`
- `/etc/odbc.ini`

## Post-Install Checks

```bash
systemctl status mariadb
systemctl status asterisk
asterisk -rx 'core show version'
asterisk -rx 'module show like codec'
```

## Caveats

- `install.sh` modifies `/etc/security/limits.conf`.
- `post-install.sh` is designed as a one-time bootstrap and exits early if
  `/usr/src/.asterisk-mysql-pass` already exists.
- Codec downloads come from `asterisk.hosting.lv`; validate that dependency
  before production use.
