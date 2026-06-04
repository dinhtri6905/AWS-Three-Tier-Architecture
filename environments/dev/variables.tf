# ============================================================
# GENERAL 
# ============================================================
variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "three-tier"
}

variable "environment" {
  description = "Deploy Environment"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

# ============================================================
# VPC 
# ============================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "app_subnets_cidrs" {
  description = "Application subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]
}

variable "db_subnets_cidrs" {
  description = "Database subnet CIDR blocks"
  type        = list(string)

  default = [
    "10.0.21.0/24",
    "10.0.22.0/24",
    "10.0.23.0/24"
  ]
}

variable "availability_zones" {
  description = "Availability Zones"
  type        = list(string)

  default = [
    "ap-southeast-1a",
    "ap-southeast-1b",
    "ap-southeast-1c"
  ]
}

# ============================================================
# SECURITY GROUP 
# ============================================================


# ============================================================
# APPLICATION LOAD BALANCER 
# ============================================================


# ============================================================
# EC2 
# ============================================================
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0543dbdaf4e114be7"
}
# ami = ami-0543dbdaf4e114be7 / ami-0d105bf3c7d10a264

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# ============================================================
# AUTOSCALING 
# ============================================================
variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4
}

# ============================================================
# RDS 
# ============================================================
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaling storage (GB)"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "db-three-tier"
}

variable "database_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "database_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}


# ============================================================
# MONITORING 
# ============================================================

variable "sns_email" {
  description = "Email nhan canh bao CloudWatch. De trong neu khong can"
  type        = string
  default     = "nguyendinhtri060905@gmail.com"
}

variable "asg_cpu_high_threshold" {
  description = "Nguong CPU cao cua ASG (%), alarm khi CPU > nguong nay"
  type        = number
  default     = 80
}

variable "asg_cpu_low_threshold" {
  description = "Nguong CPU thap cua ASG (%), alarm khi CPU < nguong nay"
  type        = number
  default     = 20
}
###
variable "rds_cpu_high_threshold" {
  description = "Nguong CPU cao cua RDS (%)"
  type        = number
  default     = 80
}

variable "rds_free_storage_threshold" {
  description = "Nguong dung luong RDS con lai (bytes). Mac dinh 5 GB"
  type        = number
  default     = 5368709120
}

variable "rds_connections_threshold" {
  description = "Nguong so ket noi RDS dong thoi"
  type        = number
  default     = 100
}

variable "alb_5xx_threshold" {
  description = "So luong loi 5xx ALB trong 1 phut"
  type        = number
  default     = 10
}

variable "alb_response_time_threshold" {
  description = "Response time trung binh cua ALB (giay), alarm khi vuot nguong nay"
  type        = number
  default     = 2
}

variable "log_retention_days" {
  description = "So ngay giu log trong CloudWatch Log Group"
  type        = number
  default     = 14

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653],
      var.log_retention_days
    )
    error_message = "log_retention_days phai la gia tri hop le cua CloudWatch: 1, 3, 5, 7, 14, 30, 60, 90, ..."
  }
}

