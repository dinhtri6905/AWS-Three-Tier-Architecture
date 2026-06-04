# ============================================================
# MODULE: VPC
# ============================================================
module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnets_cidrs
  db_subnet_cidrs     = var.db_subnets_cidrs
}

# ============================================================
# MODULE: SECURITY GROUP
# ============================================================
module "security-group" {
  source = "../../modules/security-group"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.vpc.vpc_id
}

# ============================================================
# MODULE: APPLICATION LOAD BALANCER
# ============================================================
module "alb" {
  source = "../../modules/alb"

  project_name = var.project_name
  environment  = var.environment

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security-group.alb_security_group_id
}

# ============================================================
# MODULE: EC2
# ============================================================
module "ec2" {
  source = "../../modules/ec2"

  project_name = var.project_name
  environment  = var.environment

  ami_id                = var.ami_id
  instance_type         = var.instance_type
  app_subnet_ids        = module.vpc.app_subnet_ids
  app_security_group_id = module.security-group.app_security_group_id
  target_group_arn      = module.alb.target_group_arn
}

# ============================================================
# MODULE: AUTO SCALING
# ============================================================
module "autoscaling" {
  source = "../../modules/autoscaling"

  project_name = var.project_name
  environment  = var.environment

  ami_id                = var.ami_id
  instance_type         = var.instance_type
  app_security_group_id = module.security-group.app_security_group_id

  app_subnet_ids   = module.vpc.app_subnet_ids
  target_group_arn = module.alb.target_group_arn

  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
}

# ============================================================
# MODULE: RDS
# ============================================================
module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment  = var.environment

  db_subnet_ids         = module.vpc.db_subnet_ids
  rds_security_group_id = module.security-group.rds_security_group_id

  db_instance_class     = var.db_instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  database_name     = var.database_name
  database_username = var.database_username
  database_password = var.database_password

  multi_az = var.multi_az
}

# ============================================================
# MODULE: MONITORING
# CloudWatch Alarms, Log Groups, Dashboard, SNS
# ============================================================
module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # SNS
  sns_email = var.sns_email

  # App tier
  autoscaling_group_name = module.autoscaling.autoscaling_group_name
  asg_cpu_high_threshold = var.asg_cpu_high_threshold
  asg_cpu_low_threshold  = var.asg_cpu_low_threshold

  # Data tier
  rds_instance_id            = module.rds.rds_instance_id
  rds_cpu_high_threshold     = var.rds_cpu_high_threshold
  rds_free_storage_threshold = var.rds_free_storage_threshold
  rds_connections_threshold  = var.rds_connections_threshold

  # Web tier
  alb_arn_suffix              = module.alb.alb_arn_suffix
  target_group_arn_suffix     = module.alb.target_group_arn_suffix
  alb_5xx_threshold           = var.alb_5xx_threshold
  alb_response_time_threshold = var.alb_response_time_threshold

  # Log groups
  log_retention_days = var.log_retention_days
}

