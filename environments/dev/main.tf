# ===== MODULE: VPC =====
module "vpc" {
  source = "../../modules/vpc"
  
  project_name = var.project_name
  environment = var.environment
  
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnets_cidrs = var.app_subnets_cidrs
  db_subnets_cidrs = var.db_subnets_cidrs
}

# ===== MODULE: SECURITY GROUP =====
module "security-group" {
  source = "../../modules/security-group"
}

# ===== MODULE: EC2 =====
module "ec2" {
  source = "../../modules/ec2"
}

