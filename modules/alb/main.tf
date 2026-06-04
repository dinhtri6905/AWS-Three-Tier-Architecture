locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== APPLICATION LOAD BALANCER =====
resource "aws_lb" "main" {
  #checkov:skip=CKV_AWS_150: Deletion protection disabled for lab environment
  #checkov:skip=CKV2_AWS_20: HTTPS redirect not required in lab environment
  #checkov:skip=CKV2_AWS_28: AWS WAF not required for lab environment

  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [var.alb_security_group_id]
  subnets         = var.public_subnet_ids

  drop_invalid_header_fields = true # Check: CKV_AWS_131: "Ensure that ALB drops HTTP headers"

  access_logs {
    bucket  = var.alb_logs_id
    prefix  = "alb"
    enabled = true
  }

  enable_deletion_protection = false

  tags = {
    Name        = "${local.name_prefix}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ===== TARGET GROUP =====
resource "aws_lb_target_group" "app" {
  #checkov:skip=CKV_AWS_378: Backend communication uses HTTP in lab environment

  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "${local.name_prefix}-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ===== HTTP LISTENER =====
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2: HTTP listener used in lab environment
  #checkov:skip=CKV_AWS_103: HTTP listener used for lab environment

  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "${local.name_prefix}-http-listener"
  }
}