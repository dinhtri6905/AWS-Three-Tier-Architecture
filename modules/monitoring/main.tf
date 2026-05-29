# locals {
#   name_prefix = "${var.project_name}-${var.environment}"
# }

# # ============================================================
# # SNS TOPIC
# # ============================================================

# resource "aws_sns_topic" "alerts" {
#   name = "${local.name_prefix}-alerts"
# }

# # ============================================================
# # CLOUDWATCH ALARM - AUTO SCALING CPU
# # ============================================================

# resource "aws_cloudwatch_metric_alarm" "asg_high_cpu" {
#   alarm_name          = "${local.name_prefix}-asg-high-cpu"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80

#   dimensions = {
#     AutoScalingGroupName = var.autoscaling_group_name
#   }

#   alarm_description = "Alarm when ASG average CPU exceeds 80%"

#   alarm_actions = [
#     aws_sns_topic.alerts.arn
#   ]
# }

# # ============================================================
# # CLOUDWATCH ALARM - RDS CPU
# # ============================================================

# resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
#   alarm_name          = "${local.name_prefix}-rds-high-cpu"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/RDS"
#   period              = 300
#   statistic           = "Average"
#   threshold           = 80

#   dimensions = {
#     DBInstanceIdentifier = var.rds_instance_id
#   }

#   alarm_description = "Alarm when RDS CPU exceeds 80%"

#   alarm_actions = [
#     aws_sns_topic.alerts.arn
#   ]
# }

# # ============================================================
# # CLOUDWATCH DASHBOARD
# # ============================================================

# resource "aws_cloudwatch_dashboard" "main" {
#   dashboard_name = "${local.name_prefix}-dashboard"

#   dashboard_body = jsonencode({
#     widgets = [

#       {
#         type   = "metric"
#         x      = 0
#         y      = 0
#         width  = 12
#         height = 6

#         properties = {
#           title = "Auto Scaling CPU"

#           metrics = [
#             [
#               "AWS/EC2",
#               "CPUUtilization",
#               "AutoScalingGroupName",
#               var.autoscaling_group_name
#             ]
#           ]

#           period = 300
#           stat   = "Average"
#           region = var.aws_region
#         }
#       },

#       {
#         type   = "metric"
#         x      = 12
#         y      = 0
#         width  = 12
#         height = 6

#         properties = {
#           title = "RDS CPU"

#           metrics = [
#             [
#               "AWS/RDS",
#               "CPUUtilization",
#               "DBInstanceIdentifier",
#               var.rds_instance_id
#             ]
#           ]

#           period = 300
#           stat   = "Average"
#           region = var.aws_region
#         }
#       }
#     ]
#   })
# }