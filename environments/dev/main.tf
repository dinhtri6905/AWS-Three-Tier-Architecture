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
  
  project_name = var.project_name
  environment = var.environment

  vpc_id = module.vpc.vpc_id
}

# ===== MODULE: APPLICATION LOAD BALANCER =====
module "alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  environment = var.environment

  vpc_id = module.vpc.vpc_id

  public_subnet_ids = module.vpc.public_subnet_ids

  alb_security_group_id = module.security-group.alb_security_group_id
}
# ===== MODULE: EC2 =====
module "ec2" {
  source = "../../modules/ec2"
}

# ===== MODULE: AUTO SCALING =====

# ===== MODULE: RDS =====

# ===== MODULE: MONITORING =====

