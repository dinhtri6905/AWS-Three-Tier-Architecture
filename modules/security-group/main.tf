locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Tạo SG rỗng trước — rules được thêm bên dưới bằng
# aws_security_group_rule để tránh circular dependency

# ===== SECURITY GROUP: APPLICATION LOAD BALANCER =====
resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5: Security group attached in downstream modules

  name        = "${local.name_prefix}-alb-sg"
  description = "Security Group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# ===== SECURITY GROUP: APPLICATION EC2 =====
resource "aws_security_group" "ec2" {
  #checkov:skip=CKV2_AWS_5: Security group attached in downstream modules

  name        = "${local.name_prefix}-ec2-sg"
  description = "Security Group for Application EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

# ===== SECURITY GROUP: RDS DATABASE =====
resource "aws_security_group" "rds" {
  #checkov:skip=CKV2_AWS_5: Security group attached in downstream modules

  name        = "${local.name_prefix}-rds-sg"
  description = "Security Group for RDS Database"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}
# ============================================================
# RULES: ALB SECURITY GROUP
# ============================================================

# ===== Internet -> ALB HTTP =====
resource "aws_security_group_rule" "alb_ingress_http" {
  #checkov:skip=CKV_AWS_260: Public ALB requires HTTP access from Internet in lab environment
  #checkov:skip=CKV_AWS_382: Wide egress allowed for lab environment

  type              = "ingress"
  description       = "Allow HTTP from Internet"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ===== Internet -> ALB HTTPS =====
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  description       = "Allow HTTPS from Internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ===== ALB -> outbound =====
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  description       = "Allow outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ============================================================
# RULES: EC2 SECURITY GROUP
# ============================================================

# ===== ALB -> EC2 HTTP =====
resource "aws_security_group_rule" "ec2_ingress_http_from_alb" {
  type                     = "ingress"
  description              = "Allow HTTP from ALB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.alb.id
}

# ===== ALB -> EC2 HTTPS =====
resource "aws_security_group_rule" "ec2_ingress_https_from_alb" {
  type                     = "ingress"
  description              = "Allow HTTPS from ALB"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.alb.id
}


# ===== SSH access (optional) =====
# resource "aws_security_group_rule" "ec2_ingress_ssh" {
#     type = "ingress"
#     description = "Allow SSH access"
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
#     security_group_id = aws_security_group.ec2.id

#     // Replace with your IP !!!!!!!!!!!!!!!!!!!!!!!

#     cidr_blocks = ["0.0.0.0/0"]
# }

# ===== EC2 -> outbound =====
resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  description       = "Allow outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ec2.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ============================================================
# RULES: RULES: RDS SECURITY GROUP
# ============================================================

# ===== EC2 -> RDS MySQL =====
resource "aws_security_group_rule" "rds_ingress_mysql" {
  type                     = "ingress"
  description              = "Allow MySQL from EC2"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.ec2.id
}

# ===== RDS outbound =====
resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  description       = "Allow outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["0.0.0.0/0"]
}


