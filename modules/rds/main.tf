locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== DB SUBNET GROUP =====
resource "aws_db_subnet_group" "main" {
  name = "${local.name_prefix}-db-subnet-group"

  subnet_ids = var.db_subnet_ids

  tags = {
    Name        = "${local.name_prefix}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ===== RDS MYSQL INSTANCE =====
resource "aws_db_instance" "main" {
  #checkov:skip=CKV_AWS_293: Deletion protection disabled for lab environment
  #checkov:skip=CKV_AWS_129: RDS log exports not required for lab environment
  #checkov:skip=CKV_AWS_161: IAM database authentication not required for lab environment
  #checkov:skip=CKV_AWS_157: Multi-AZ disabled for cost optimization in lab environment

  #checkov:skip=CKV_AWS_118: Enhanced monitoring not required for lab environment
  
  identifier = "${local.name_prefix}-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = var.db_instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  storage_type = "gp3"
  # CKV_AWS_16 - RDS Encryption at Rest
  storage_encrypted = true
  
  auto_minor_version_upgrade = true

  db_name  = var.database_name
  username = var.database_username
  password = var.database_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]

  multi_az = var.multi_az

  publicly_accessible = false

  backup_retention_period = 7

  skip_final_snapshot = true

  deletion_protection = false

  copy_tags_to_snapshot = true
  
  tags = {
    Name        = "${local.name_prefix}-rds"
    Environment = var.environment
    Project     = var.project_name
  }
}