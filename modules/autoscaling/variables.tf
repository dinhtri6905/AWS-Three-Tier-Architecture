variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Deploy Environment"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for Template"
  type        = string
}
# ami = ami-0543dbdaf4e114be7 / ami-0d105bf3c7d10a264

variable "instance_type" {
  description = "Instance type for Template"
  type        = string
}

variable "app_security_group_id" {
  description = "Security Group ID for Template"
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnet IDs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB Target Group ARN"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
}