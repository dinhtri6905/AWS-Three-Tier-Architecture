# ============================================================
# SNS
# ============================================================

output "sns_topic_arn" {
  description = "ARN cua SNS topic nhan canh bao"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Ten SNS topic"
  value       = aws_sns_topic.alerts.name
}

# ============================================================
# CLOUDWATCH ALARMS
# ============================================================

output "asg_cpu_high_alarm_name" {
  description = "Ten CloudWatch alarm ASG CPU cao"
  value       = aws_cloudwatch_metric_alarm.asg_cpu_high.alarm_name
}

output "asg_cpu_low_alarm_name" {
  description = "Ten CloudWatch alarm ASG CPU thap"
  value       = aws_cloudwatch_metric_alarm.asg_cpu_low.alarm_name
}

output "rds_cpu_alarm_name" {
  description = "Ten CloudWatch alarm RDS CPU cao"
  value       = aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name
}

output "rds_free_storage_alarm_name" {
  description = "Ten CloudWatch alarm RDS dung luong thap"
  value       = aws_cloudwatch_metric_alarm.rds_free_storage_low.alarm_name
}

output "rds_connections_alarm_name" {
  description = "Ten CloudWatch alarm RDS ket noi cao"
  value       = aws_cloudwatch_metric_alarm.rds_connections_high.alarm_name
}

output "alb_5xx_alarm_name" {
  description = "Ten CloudWatch alarm ALB 5xx loi"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_high.alarm_name
}

output "alb_response_time_alarm_name" {
  description = "Ten CloudWatch alarm ALB response time"
  value       = aws_cloudwatch_metric_alarm.alb_response_time_high.alarm_name
}

output "alb_unhealthy_hosts_alarm_name" {
  description = "Ten CloudWatch alarm ALB unhealthy hosts"
  value       = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.alarm_name
}

# ============================================================
# LOG GROUPS
# ============================================================

output "app_log_group_name" {
  description = "Ten CloudWatch Log Group cua App tier"
  value       = aws_cloudwatch_log_group.app.name
}

output "web_log_group_name" {
  description = "Ten CloudWatch Log Group cua Web tier"
  value       = aws_cloudwatch_log_group.web.name
}

# ============================================================
# DASHBOARD
# ============================================================

output "dashboard_name" {
  description = "Ten CloudWatch Dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL truy cap CloudWatch Dashboard tren AWS Console"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
