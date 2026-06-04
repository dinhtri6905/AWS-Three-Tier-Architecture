variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Deploy Environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security Group ID for Application Load Balancer"
  type        = string
}

variable "alb_logs_id" {
  description = "ID của S3 Bucket (ALB Logs)"
  type        = string
}
