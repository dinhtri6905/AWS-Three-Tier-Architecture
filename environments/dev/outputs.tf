# ============================================================
# VPC
# ============================================================
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "app_subnet_ids" {
  description = "Application Subnet IDs"
  value       = module.vpc.app_subnet_ids
}

output "db_subnet_ids" {
  description = "Database Subnet IDs"
  value       = module.vpc.db_subnet_ids
}

# ============================================================
# SECURITY GROUPS
# ============================================================
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = module.security-group.alb_security_group_id
}

output "web_security_group_id" {
  description = "Web Tier Security Group ID"
  value       = module.security-group.web_security_group_id
}

output "app_security_group_id" {
  description = "Application Tier Security Group ID"
  value       = module.security-group.app_security_group_id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = module.security-group.rds_security_group_id
}

# ============================================================
# ALB
# ============================================================
output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = module.alb.alb_dns_name
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = module.alb.target_group_arn
}

# ============================================================
# EC2
# ============================================================
output "web_instance_ids" {
  description = "Web Tier EC2 Instance IDs"
  value       = module.ec2.instance_ids
}

# ============================================================
# AUTOSCALING
# ============================================================
output "autoscaling_group_name" {
  description = "Auto Scaling Group Name"
  value       = module.autoscaling.autoscaling_group_name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = module.autoscaling.launch_template_id
}

# ============================================================
# RDS
# ============================================================
output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = module.rds.rds_endpoint
}

output "rds_identifier" {
  description = "RDS Identifier"
  value       = module.rds.rds_identifier
}

output "rds_arn" {
  description = "RDS ARN"
  value       = module.rds.rds_arn
}