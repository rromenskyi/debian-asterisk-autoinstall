# Operations

This repository includes a few helper scripts for day-2 operations.

## Backups

Run:

```bash
sudo ./backup.sh
```

This installs:

- `/etc/asterisk-backup.conf`
- `/usr/local/bin/backup_script.sh`
- `backup.service`
- `backup.timer`

The generated backup job archives:

- `/etc/asterisk`
- `/var/lib/asterisk`
- `asteriskcdrdb` via `mysqldump`

Default retention removes generated `.gz` archives older than 14 days.

## Packet Capture

Run:

```bash
sudo ./tcpdump.sh
```

This installs:

- `/etc/asterisk-tcpdump.conf`
- `/usr/local/bin/tcpdump_script.sh`
- `tcpdump.service`
- `tcpdump.timer`

The generated capture job writes SIP captures for port `5060` into
`/opt/dump` and removes captures older than 7 days.

## CDR Archive

Run:

```bash
sudo ./cdr-archive.sh
```

This installs:

- `/etc/asterisk-cdr-archive.conf`
- `/usr/local/bin/cdr_archive_script.sh`
- `cdr-archive.service`
- `cdr-archive.timer`

The generated job fires on the 2nd of each month, gathers CDR files from
`/var/cdrs` that match the previous month's `YYYYMM*` prefix, concatenates
them into a single `YYYYMM.cdr`, compresses it to `/var/cdr-arch/YYYYMM.cdr.7z`,
verifies the archive, and then removes the original CDR files. Archives older
than 365 days are pruned.

## User Bootstrap

[`newuser.sh`](../newuser.sh) is an example helper that creates a local user,
adds it to `sudo`, and installs a public SSH key.

Edit these variables before running it:

- `USERNAME`
- `GROUPNAME`
- `SSH_PUBLIC_KEY`

## Terraform Example

`tf-example/` contains an AWS example with:

- A VPC and subnet
- A security group with broad ingress rules
- Two EC2 instances running containerized web servers

Use it as a scratchpad example only. It is not tuned for production security.
