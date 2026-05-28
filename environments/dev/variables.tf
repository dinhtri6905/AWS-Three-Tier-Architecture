# ========== GENERAL ==========
variable "project_name" {
  description = "Project Name"
  type = string
  default = "three-tier"
}

variable "environment" {
  description = "Deploy Environment"
  type = string
  default = "dev"
}

variable "aws_region" {
  description = "AWS Region"
  type = string
  default = "ap-southeast-1"
}

# ========== VPC ==========
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type = string
  default = "10.0.0.0/16"
}

  variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "app_subnets_cidrs" {
  description = "Application subnet CIDR blocks"
  type = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]
}

variable "db_subnets_cidrs" {
  description = "Database subnet CIDR blocks"
  type = list(string)

  default = [
    "10.0.21.0/24",
    "10.0.22.0/24",
    "10.0.23.0/24"
  ]
}

variable "availability_zones" {
  description = "Availability Zones"
  type = list(string)

  default = [
    "ap-southeast-1a",
    "ap-southeast-1b",
    "ap-southeast-1c"
  ]
}

# ========== SECURITY GROUP ==========


# ========== APPLICATION LOAD BALANCER ==========


# ========== EC2 ==========
variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default = "ami-0543dbdaf4e114be7"
}
# ami = ami-0543dbdaf4e114be7 / ami-0d105bf3c7d10a264

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default = "t3.micro"
}

# ========== AUTOSCALING ==========


# ========== RDS ==========


# ========== MONITORING ==========


