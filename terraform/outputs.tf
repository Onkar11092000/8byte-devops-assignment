# ---------------------------------------------------------
# VPC Outputs
# ---------------------------------------------------------

output "vpc_id" {
  description = "ID of the staging VPC"
  value       = aws_vpc.main.id
}

# ---------------------------------------------------------
# EC2 Outputs
# ---------------------------------------------------------

output "ec2_instance_id" {
  description = "Application EC2 instance ID"
  value       = aws_instance.app.id
}

output "ec2_private_ip" {
  description = "Private IP address of application EC2"
  value       = aws_instance.app.private_ip
}

# ---------------------------------------------------------
# RDS Outputs
# ---------------------------------------------------------

output "rds_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "PostgreSQL RDS port"
  value       = aws_db_instance.postgres.port
}

# ---------------------------------------------------------
# Load Balancer Outputs
# ---------------------------------------------------------

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.app.dns_name
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_lb.app.dns_name}"
}

output "app_public_ip" {
  description = "Public IP address of the application server"
  value       = aws_instance.app.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the application server"
  value       = "ssh -i ./ssh_key.pem ubuntu@${aws_instance.app.public_ip}"
}
