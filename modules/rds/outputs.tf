output "rds_instance_id" {
  description = "RDS Instance ID"
  value       = aws_db_instance.main.id
}

output "rds_instance_arn" {
  description = "RDS Instance ARN"
  value       = aws_db_instance.main.arn
}

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS Address"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS Port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database Name"
  value       = aws_db_instance.main.db_name
}

output "database_username" {
  description = "Database Username"
  value       = aws_db_instance.main.username
  sensitive   = true
}