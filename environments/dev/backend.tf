# terraform {
#   backend "s3" {
#     bucket         = "three-tier-terraform-state"
#     key            = "dev/terraform.tfstate"
#     region         = "ap-southeast-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }