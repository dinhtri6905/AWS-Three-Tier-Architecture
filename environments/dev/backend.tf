terraform {
  backend "s3" {
    bucket         = "three-tier-terraform-state-2026"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}