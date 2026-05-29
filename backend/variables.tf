variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-1"
}

variable "tfstate_bucket_name" {
  description = "Terraform State S3 Bucket Name"
  type        = string
  default     = "three-tier-terraform-state"
}

variable "dynamodb_lock_table_name" {
  description = "Terraform Lock DynamoDB Table Name"
  type        = string
  default     = "terraform-locks"
}
