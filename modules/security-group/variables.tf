variable "project_name" {
  description = "Project Name"
  type = string
}

variable "environment" {
  description = "Deploy Environment"
  type = string
  default = "dev"
}

variable "vpc_id" {
  description = "VPC ID"
  type = string
}