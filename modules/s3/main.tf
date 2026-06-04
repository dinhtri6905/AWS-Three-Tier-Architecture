locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ============================================================
# Tạo S3 Bucket để lưu log ALB
# ============================================================
resource "aws_s3_bucket" "alb_logs" {
  #checkov:skip=CKV_AWS_18: Access logging bucket does not require self logging
  #checkov:skip=CKV_AWS_144: Cross region replication not required for lab environment
  #checkov:skip=CKV2_AWS_62: Event notifications not required for ALB log bucket
  #checkov:skip=CKV_AWS_145: AES256 encryption sufficient for lab environment

  bucket = "${local.name_prefix}-alb-logs"

  tags = {
    Name = "${local.name_prefix}-alb-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  #checkov:skip=CKV_AWS_300: Multipart upload cleanup not required for ALB log bucket

  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "expire_old_logs"
    status = "Enabled"

    expiration {
      days = 30
    }

    # abort_incomplete_multipart_upload {
    #   days_after_initiation = 7
    # }
  }
}

# resource "aws_s3_bucket_policy" "alb_logs" {
#   bucket = aws_s3_bucket.alb_logs.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AWSALBLogs"
#         Effect = "Allow"

#         Principal = {
#           Service = "logdelivery.elasticloadbalancing.amazonaws.com"
#         }

#         Action = [
#           "s3:PutObject"
#         ]

#         Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/*"
#       }
#     ]
#   })
# }