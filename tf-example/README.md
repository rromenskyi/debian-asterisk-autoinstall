# tf-example

AWS example that launches a Debian 12 EC2 instance and bootstraps the Asterisk
installation from this repository via `user_data`.

## What It Creates

- dedicated VPC
- one public subnet
- internet gateway and route table
- security group for SSH, SIP, and RTP
- one Debian 12 EC2 instance

The instance bootstrap writes the current repository versions of:

- [`../install.sh`](../install.sh)
- [`../post-install.sh`](../post-install.sh)
- [`../cdr.sql`](../cdr.sql)

and then runs them on first boot.

## Inputs You Must Review

- `key_name` or `ssh_public_key`
- `allowed_ssh_cidrs`
- `allowed_sip_cidrs`
- `allowed_rtp_cidrs`

The defaults are easy to start with, but they are deliberately permissive for
SIP and RTP and should be tightened before any real exposure.

## Quick Start

```bash
cd tf-example
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## After Apply

Debian EC2 images use the SSH user `admin`.

```bash
ssh admin@$(terraform output -raw public_ip)
```

Bootstrap logs are written to:

```bash
sudo tail -f /var/log/asterisk-bootstrap.log
```

## AMI Source

The configuration resolves the most recent official Debian 12 AMD64 AMI by
default using Debian's published EC2 owner account.

You can override this with `ami_id` if you want to pin a specific image.
