# Debian Asterisk Autoinstall

Automation scripts, Docker examples, and operations helpers for deploying
Asterisk Certified 18 on Debian 12.

## Overview

This repository bundles the shell scripts and examples used to bootstrap an
Asterisk host, initialize MariaDB for CDR, enable a few operational timers, and
experiment with containerized or cloud-based layouts.

It is aimed at operators who want a practical starting point rather than a
fully hardened distribution package.

## What Is Included

| Path | Purpose |
| --- | --- |
| `install.sh` | Installs OS packages, fail2ban, build dependencies, pjproject, sngrep, and Asterisk Certified. |
| `post-install.sh` | Creates MariaDB users/databases, imports the bundled CDR schema, sets ownership, and writes service/logrotate config. |
| `backup.sh` | Installs a systemd timer for daily Asterisk config/data/CDR backups. |
| `tcpdump.sh` | Installs a systemd timer for SIP packet captures. |
| `newuser.sh` | Example helper for creating a sudo-enabled user with an SSH public key. |
| `cdr.sql` | SQL schema imported by `post-install.sh` for `asteriskcdrdb`. |
| `dockerfiles/` | Standalone Dockerfiles plus a compose stack with Asterisk, MariaDB, Kamailio, RTPengine, and PHP-FPM. |
| `tf-example/` | Terraform example that provisions a Debian 12 EC2 VM and bootstraps this repository's Asterisk install on first boot. |
| `agi-bin/` | AGI and helper scripts used by the telephony stack. |

## Quick Start

These scripts are intended for a fresh Debian 12 host and should be reviewed
before execution.

```bash
git clone https://github.com/rromenskyi/debian-asterisk-autoinstall.git
cd debian-asterisk-autoinstall

sudo ./install.sh
sudo ./post-install.sh
```

After the base install you can optionally enable:

```bash
sudo ./backup.sh
sudo ./tcpdump.sh
```

Detailed walkthroughs:

- Manual install: [docs/manual-install.md](docs/manual-install.md)
- Docker/compose stack: [docs/docker-compose.md](docs/docker-compose.md)
- Operations and maintenance: [docs/operations.md](docs/operations.md)

## Important Notes

- The scripts expect root privileges or `sudo`.
- `post-install.sh` downloads `codec_g729.so` and `codec_g723.so` from a
  third-party host. Review that step before using it in production.
- The compose stack uses `network_mode: host` and example credentials. Treat it
  as a lab or baseline environment until you harden it.
- `tf-example/` is now wired to a Debian 12 EC2 host and the repository's
  install scripts, but the default network rules are still intentionally broad
  enough for first boot and should be tightened before production use.

## Suggested Execution Order

1. Prepare a fresh Debian 12 VM or bare-metal host.
2. Review and edit any hard-coded values you do not want to keep.
3. Run `install.sh`.
4. Run `post-install.sh`.
5. Add optional maintenance timers with `backup.sh` and `tcpdump.sh`.
6. Customize Asterisk dialplan, SIP/PJSIP config, and AGI scripts for your
   environment.

## Repository Layout

```text
.
├── agi-bin/              AGI and helper scripts
├── dockerfiles/          Container images and compose examples
├── tf-example/           Terraform example for a Debian 12 Asterisk VM on AWS
├── backup.sh             Backup timer installer
├── cdr.sql               CDR schema
├── install.sh            Base host installer
├── newuser.sh            User bootstrap helper
├── post-install.sh       DB and service configuration
└── tcpdump.sh            Tcpdump timer installer
```

## Status

This repository now documents the intended flow and the purpose of each script,
but you should still treat it as operator-maintained infrastructure code:
review, adapt, and test it in your own environment before production rollout.
