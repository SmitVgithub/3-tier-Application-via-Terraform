# outputs.tf
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

output "db_public_ip" {
  value = aws_instance.database.public_ip
}

output "frontend_lb_dns" {
  value = aws_lb.frontend_lb.dns_name
}

output "backend_lb_dns" {
  value = aws_lb.backend_lb.dns_name
}
