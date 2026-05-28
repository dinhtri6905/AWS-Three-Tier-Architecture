variable "project_name" {
  description = "Project Name"
  type = string
}

variable "environment" {
  description = "Deploy Environment"
  type = string
  default = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type = string
}

  variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type = list(string)
}

variable "app_subnets_cidrs" {
  description = "Application subnet CIDR blocks"
  type = list(string)
}

variable "db_subnets_cidrs" {
  description = "Database subnet CIDR blocks"
  type = list(string)
}

variable "availability_zones" {
  description = "Availability Zones"
  type = list(string)
}