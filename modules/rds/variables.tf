variable "project_name" {
  description = "Project Name"
  type = string
}

variable "environment" {
  description = "Deploy Environment"
  type = string
  default = "dev"
}

variable "db_subnet_ids" {
  description = "Database subnet IDs"
  type = list(string)
}

variable "rds_security_group_id" {
  description = "RDS Security Group ID"
  type = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage (GB)"
  type = number
  default = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaling storage (GB)"
  type = number
  default = 100
}

variable "database_name" {
  description = "Database name"
  type = string
  default = "db-three-tier"
}

variable "database_username" {
  description = "Database master username"
  type = string
  default = "admin"
}

variable "database_password" {
  description = "Database master password"
  type = string
  sensitive = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type = bool
  default = false
}
