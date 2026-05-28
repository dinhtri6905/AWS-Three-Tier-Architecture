# ===== MODULE: VPC =====
module "vpc" {
  source = "../../modules/vpc"
  
  project_name = var.project_name
  environment = var.environment

  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs = var.app_subnets_cidrs
  db_subnet_cidrs = var.db_subnets_cidrs
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

  project_name = var.project_name
  environment = var.environment

  ami_id = var.ami_id
  instance_type = var.instance_type
  app_subnet_ids = module.vpc.app_subnet_ids
  ec2_security_group_id = module.security-group.ec2_security_group_id
  target_group_arn = module.alb.target_group_arn
}

# ===== MODULE: AUTO SCALING =====
module "autoscaling" {
  source = "../../modules/autoscaling"

  project_name = var.project_name
  environment = var.environment

}

# ===== MODULE: RDS =====
module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment = var.environment

}
# ===== MODULE: MONITORING =====
module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment = var.environment

}
