variable "project_name" {
description = "Project name"
type        = string
}

variable "environment" {
description = "Deployment environment"
type        = string
}

variable "ami_id" {
description = "AMI ID for EC2 instances"
type        = string
}
# ami = ami-0543dbdaf4e114be7 / ami-0d105bf3c7d10a264

variable "instance_type" {
description = "EC2 instance type"
type        = string
}

variable "app_subnet_ids" {
description = "Application subnet IDs"
type        = list(string)
}

variable "ec2_security_group_id" {
description = "Security Group ID for EC2 instances"
type        = string
}

variable "target_group_arn" {
description = "ALB Target Group ARN"
type        = string
}

