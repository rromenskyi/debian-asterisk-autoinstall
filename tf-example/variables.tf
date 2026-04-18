variable "aws_region" {
  description = "AWS region where the Asterisk VM will be created."
  type        = string
  default     = "eu-central-1"
}

variable "availability_zone" {
  description = "Optional availability zone for the public subnet."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Prefix used for Terraform-created AWS resources."
  type        = string
  default     = "debian-asterisk"
}

variable "instance_type" {
  description = "EC2 instance type for the Debian Asterisk host."
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name to attach to the instance."
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "Optional SSH public key material. If set, Terraform creates an EC2 key pair automatically."
  type        = string
  default     = null
}

variable "ami_id" {
  description = "Optional AMI override. Leave null to discover the latest official Debian 12 AMI."
  type        = string
  default     = null
}

variable "debian_release" {
  description = "Debian release number used when resolving the official AMI."
  type        = string
  default     = "12"
}

variable "debian_ami_owner" {
  description = "AWS account ID used by the Debian cloud team for official AMIs."
  type        = string
  default     = "136693071363"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet where the Asterisk host is created."
  type        = string
  default     = "10.42.10.0/24"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to the instance."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_sip_cidrs" {
  description = "CIDR blocks allowed to reach SIP ports 5060/5061."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_rtp_cidrs" {
  description = "CIDR blocks allowed to reach the RTP media range 10000-20000/udp."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_icmp" {
  description = "Whether to allow ICMP echo requests to the instance."
  type        = bool
  default     = true
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size for the Debian instance."
  type        = number
  default     = 32
}

variable "asterisk_timezone" {
  description = "Timezone exported into the bootstrap script before installing Asterisk."
  type        = string
  default     = "UTC"
}

variable "offline_plan_mode" {
  description = "Set true only for speculative CI plans that should not call live AWS APIs."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional AWS tags to apply to created resources."
  type        = map(string)
  default     = {}
}
