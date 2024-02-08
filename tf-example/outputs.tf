output "nginx_public_ip" {
  value = aws_instance.nginx_instance.public_ip
}

output "apache2_public_ip" {
  value = aws_instance.apache2_instance.public_ip
}