provider "aws" {
  region = var.aws_region

  # CI can use this mode for speculative plans without live AWS credentials.
  skip_credentials_validation = var.offline_plan_mode
  skip_metadata_api_check     = var.offline_plan_mode
  skip_region_validation      = var.offline_plan_mode
  skip_requesting_account_id  = var.offline_plan_mode
}

locals {
  bootstrap_dir = "/opt/debian-asterisk-autoinstall"
  key_name      = local.using_generated_key ? aws_key_pair.this[0].key_name : var.key_name
  tags = merge(
    {
      Project = var.project_name
      Managed = "terraform"
    },
    var.tags,
  )
  using_generated_key = var.ssh_public_key != null && trimspace(var.ssh_public_key) != ""
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-subnet"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "asterisk" {
  name        = "${var.project_name}-asterisk-sg"
  description = "Security group for Debian Asterisk host"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${var.project_name}-asterisk-sg"
  })
}

resource "aws_security_group_rule" "ssh" {
  for_each = toset(var.allowed_ssh_cidrs)

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.asterisk.id
}

resource "aws_security_group_rule" "sip_udp" {
  for_each = toset(var.allowed_sip_cidrs)

  type              = "ingress"
  from_port         = 5060
  to_port           = 5060
  protocol          = "udp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.asterisk.id
}

resource "aws_security_group_rule" "sip_tcp" {
  for_each = toset(var.allowed_sip_cidrs)

  type              = "ingress"
  from_port         = 5060
  to_port           = 5060
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.asterisk.id
}

resource "aws_security_group_rule" "sip_tls" {
  for_each = toset(var.allowed_sip_cidrs)

  type              = "ingress"
  from_port         = 5061
  to_port           = 5061
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.asterisk.id
}

resource "aws_security_group_rule" "rtp" {
  for_each = toset(var.allowed_rtp_cidrs)

  type              = "ingress"
  from_port         = 10000
  to_port           = 20000
  protocol          = "udp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.asterisk.id
}

resource "aws_security_group_rule" "icmp" {
  count = var.enable_icmp ? 1 : 0

  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.asterisk.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.asterisk.id
}

resource "aws_key_pair" "this" {
  count = local.using_generated_key ? 1 : 0

  key_name   = "${var.project_name}-admin"
  public_key = var.ssh_public_key

  tags = merge(local.tags, {
    Name = "${var.project_name}-admin"
  })
}

data "aws_ami" "debian_12" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = [var.debian_ami_owner]

  filter {
    name   = "name"
    values = ["debian-${var.debian_release}-amd64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  debian_ami_id = coalesce(var.ami_id, one(data.aws_ami.debian_12[*].id))
}

resource "aws_instance" "asterisk" {
  ami                         = local.debian_ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = local.key_name
  vpc_security_group_ids      = [aws_security_group.asterisk.id]
  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/cloud-init-asterisk.tftpl", {
    bootstrap_dir   = local.bootstrap_dir
    install_sh      = file("${path.module}/../install.sh")
    post_install_sh = file("${path.module}/../post-install.sh")
    cdr_sql         = file("${path.module}/../cdr.sql")
    timezone        = var.asterisk_timezone
  })

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-asterisk"
  })

  lifecycle {
    precondition {
      condition     = local.using_generated_key || (var.key_name != null && trimspace(var.key_name) != "")
      error_message = "Set either key_name or ssh_public_key so the Debian EC2 instance can be accessed over SSH."
    }
  }
}
