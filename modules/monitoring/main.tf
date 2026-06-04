locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ============================================================
# SNS TOPIC + EMAIL SUBSCRIPTION
# ============================================================
resource "aws_sns_topic" "alerts" {
  #checkov:skip=CKV_AWS_26: SNS encryption not required for lab environment

  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count = var.sns_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

# ============================================================
# CLOUDWATCH ALARMS — APP TIER (Auto Scaling Group)
# ============================================================
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${local.name_prefix}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.asg_cpu_high_threshold

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_description = "App tier ASG CPU vuot ${var.asg_cpu_high_threshold}%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_low" {
  alarm_name          = "${local.name_prefix}-asg-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.asg_cpu_low_threshold

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_description = "App tier ASG CPU thap hon ${var.asg_cpu_low_threshold}%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
}

# ============================================================
# CLOUDWATCH ALARMS — DATA TIER (RDS)
# ============================================================
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_cpu_high_threshold

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_description = "RDS CPU vuot ${var.rds_cpu_high_threshold}%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${local.name_prefix}-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_free_storage_threshold

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_description = "RDS free storage con lai duoi ${var.rds_free_storage_threshold / 1073741824} GB"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${local.name_prefix}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_connections_threshold

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_description = "RDS so ket noi dong thoi vuot ${var.rds_connections_threshold}"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

# ============================================================
# CLOUDWATCH ALARMS — WEB TIER (ALB)
# ============================================================
resource "aws_cloudwatch_metric_alarm" "alb_5xx_high" {
  alarm_name          = "${local.name_prefix}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "ALB tra ve 5xx loi vuot ${var.alb_5xx_threshold} lan trong 1 phut"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  alarm_name          = "${local.name_prefix}-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = var.alb_response_time_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "ALB response time trung binh vuot ${var.alb_response_time_threshold}s"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${local.name_prefix}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_description = "Co target khong healthy trong ALB target group"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

# ============================================================
# CLOUDWATCH LOG GROUPS
# ============================================================
resource "aws_cloudwatch_log_group" "app" {
  #checkov:skip=CKV_AWS_158: KMS encryption not required for lab environment

  name              = "/aws/ec2/${local.name_prefix}/app"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "web" {
  #checkov:skip=CKV_AWS_158: KMS encryption not required for lab environment

  name              = "/aws/ec2/${local.name_prefix}/web"
  retention_in_days = var.log_retention_days
}

# ============================================================
# CLOUDWATCH DASHBOARD
# ============================================================
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # Row 1: App tier CPU | RDS CPU
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "App Tier - ASG CPU Utilization (%)"
          region = var.aws_region
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/EC2", "CPUUtilization",
            "AutoScalingGroupName", var.autoscaling_group_name]
          ]
          annotations = {
            horizontal = [
              { value = var.asg_cpu_high_threshold, label = "High", color = "#ff0000" },
              { value = var.asg_cpu_low_threshold, label = "Low", color = "#0000ff" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Data Tier - RDS CPU Utilization (%)"
          region = var.aws_region
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "CPUUtilization",
            "DBInstanceIdentifier", var.rds_instance_id]
          ]
          annotations = {
            horizontal = [
              { value = var.rds_cpu_high_threshold, label = "High", color = "#ff0000" }
            ]
          }
        }
      },

      # Row 2: RDS Free Storage | RDS Connections
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Data Tier - RDS Free Storage (Bytes)"
          region = var.aws_region
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace",
            "DBInstanceIdentifier", var.rds_instance_id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Data Tier - RDS DB Connections"
          region = var.aws_region
          period = 300
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "DatabaseConnections",
            "DBInstanceIdentifier", var.rds_instance_id]
          ]
        }
      },

      # Row 3: ALB 5xx | ALB Response Time
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Web Tier - ALB 5XX Error Count"
          region = var.aws_region
          period = 60
          stat   = "Sum"
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count",
            "LoadBalancer", var.alb_arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Web Tier - ALB Target Response Time (s)"
          region = var.aws_region
          period = 60
          stat   = "Average"
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime",
            "LoadBalancer", var.alb_arn_suffix]
          ]
          annotations = {
            horizontal = [
              { value = var.alb_response_time_threshold, label = "Threshold", color = "#ff6600" }
            ]
          }
        }
      }

    ]
  })
}
