output "alb_id" {
  description = "Application Load Balancer ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ALB ARN Suffix"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "DNS Name of the ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer Zone ID"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.app.arn
}

output "target_group_name" {
  description = "Target Group Name"
  value       = aws_lb_target_group.app.name
}

output "target_group_arn_suffix" {
  description = "Target Group ARN Suffix"
  value       = aws_lb_target_group.app.arn_suffix
}

output "http_listener_arn" {
  description = "HTTP Listener ARN"
  value       = aws_lb_listener.http.arn
}
