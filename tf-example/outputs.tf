output "instance_id" {
  description = "EC2 instance ID of the Debian Asterisk host."
  value       = aws_instance.asterisk.id
}

output "public_ip" {
  description = "Public IPv4 address of the Debian Asterisk host."
  value       = aws_instance.asterisk.public_ip
}

output "public_dns" {
  description = "Public DNS name of the Debian Asterisk host."
  value       = aws_instance.asterisk.public_dns
}

output "ssh_user" {
  description = "Default SSH user for official Debian EC2 AMIs."
  value       = "admin"
}

output "ssh_command" {
  description = "Convenience SSH command for the created instance."
  value       = "ssh admin@${aws_instance.asterisk.public_ip}"
}

output "ami_id" {
  description = "AMI ID used for the Debian instance."
  value       = aws_instance.asterisk.ami
}
