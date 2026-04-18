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
