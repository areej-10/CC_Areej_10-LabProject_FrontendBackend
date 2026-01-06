output "frontend_public_ip" {
  # References the direct aws_instance resource instead of a module
  value = aws_instance.frontend.public_ip
}

output "backend_public_ips" {
  # Uses a 'for' loop to get public IPs from the backend resource array
  value = [for b in aws_instance.backend : b.public_ip]
}

output "backend_private_ips" {
  # Uses a 'for' loop to get private IPs for the Nginx upstream configuration
  value = [for b in aws_instance.backend : b.private_ip]
}