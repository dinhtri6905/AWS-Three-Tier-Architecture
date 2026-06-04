output "alb_logs_id" {
  description = "ID of S3 Bucket (ALB Logs)"
  value = aws_s3_bucket.alb_logs.id
}