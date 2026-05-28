output "alb_security_group_id" {
description = "Security Group ID for Application Load Balancer"
value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
description = "Security Group ID for EC2 Application Servers"
value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
description = "Security Group ID for RDS Database"
value       = aws_security_group.rds.id
}
