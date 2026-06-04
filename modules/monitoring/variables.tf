variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Deploy Environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region, dung cho CloudWatch Dashboard"
  type        = string
}

# ============================================================
# SNS
# ============================================================

variable "sns_email" {
  description = "Email nhan canh bao tu SNS. De trong ('') neu khong muon subscribe"
  type        = string
  default     = ""
}

# ============================================================
# APP TIER — Auto Scaling Group
# ============================================================

variable "autoscaling_group_name" {
  description = "Ten cua Auto Scaling Group (output tu module autoscaling)"
  type        = string
}

variable "asg_cpu_high_threshold" {
  description = "Nguong CPU cao cua ASG (%), alarm khi CPU > gia tri nay"
  type        = number
}

variable "asg_cpu_low_threshold" {
  description = "Nguong CPU thap cua ASG (%), alarm khi CPU < gia tri nay"
  type        = number
}

# ============================================================
# DATA TIER — RDS
# ============================================================

variable "rds_instance_id" {
  description = "DB Instance Identifier cua RDS (output tu module rds)"
  type        = string
}

variable "rds_cpu_high_threshold" {
  description = "Nguong CPU cao cua RDS (%)"
  type        = number
}

variable "rds_free_storage_threshold" {
  description = "Nguong dung luong RDS con lai (bytes), alarm khi FreeStorage < gia tri nay. Mac dinh 5 GB"
  type        = number
}

variable "rds_connections_threshold" {
  description = "Nguong so ket noi RDS dong thoi, alarm khi DatabaseConnections > gia tri nay"
  type        = number
}

# ============================================================
# WEB TIER — ALB
# ============================================================

variable "alb_arn_suffix" {
  description = "ARN suffix cua ALB dung cho CloudWatch dimensions (aws_lb.main.arn_suffix)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix cua Target Group dung cho CloudWatch dimensions (aws_lb_target_group.main.arn_suffix)"
  type        = string
}

variable "alb_5xx_threshold" {
  description = "So luong loi 5xx trong 1 phut, alarm khi vuot nguong nay"
  type        = number
  default     = 10
}

variable "alb_response_time_threshold" {
  description = "Response time trung binh cua ALB (giay), alarm khi vuot nguong nay"
  type        = number
}

# ============================================================
# LOG GROUPS
# ============================================================

variable "log_retention_days" {
  description = "So ngay giu log trong CloudWatch Log Group"
  type        = number
  # default     = 14

  # validation {
  #   condition = contains(
  #     [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653],
  #     var.log_retention_days
  #   )
  #   error_message = "log_retention_days phai la gia tri hop le cua CloudWatch: 1, 3, 5, 7, 14, 30, 60, 90, ..."
  # }
}

