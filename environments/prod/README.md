# Environment: Prod

Cấu hình Terraform cho môi trường **Production** của kiến trúc ba tầng AWS. Môi trường prod sử dụng cấu hình mạnh hơn, bật Multi-AZ, deletion protection và tuân thủ nghiêm ngặt theo CIS AWS Foundations Benchmark v1.5.0.

---

## Trạng thái hiện tại

> **Môi trường production chưa được cấu hình.** Các file hiện tại (`main.tf`, `variables.tf`, `outputs.tf`, v.v.) đang để trống. Cần điền đầy đủ trước khi deploy lên production.

---

## Cấu trúc file

```
environments/prod/
├── backend.tf          # Remote state: s3://bucket/prod/terraform.tfstate
├── main.tf             # Gọi các module (chưa cấu hình)
├── variables.tf        # Khai báo biến (chưa cấu hình)
├── outputs.tf          # Outputs (chưa cấu hình)
├── providers.tf        # AWS provider (chưa cấu hình)
└── versions.tf         # Terraform version (chưa cấu hình)
```

---

## Khác biệt so với Dev

| Thuộc tính | Dev | Production |
|-----------|-----|------------|
| `instance_type` | `t3.micro` | `t3.medium` hoặc lớn hơn |
| `db_instance_class` | `db.t3.micro` | `db.t3.medium` hoặc lớn hơn |
| `multi_az` | `false` | **`true`** — bắt buộc |
| `deletion_protection` | `false` | **`true`** — bắt buộc |
| `skip_final_snapshot` | `true` | **`false`** — lưu snapshot trước destroy |
| `min_size` ASG | `1` | `2` trở lên |
| `log_retention_days` | `7` | `30` hoặc lâu hơn |
| ALB access_logs | Tắt | **Bật** |
| HTTPS Listener | Tắt | **Bật** (ACM certificate) |
| WAF | Không có | Khuyến nghị gắn WAF |
| CloudTrail | Không có | **Bắt buộc** (OPA compliance deny) |

---

## Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "<BUCKET_TF_STATE>"
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

State của prod được lưu tách biệt với dev tại key `prod/terraform.tfstate`.

---

## Hướng dẫn cấu hình production

### 1. Copy cấu hình từ dev

```bash
cp environments/dev/main.tf environments/prod/main.tf
cp environments/dev/variables.tf environments/prod/variables.tf
cp environments/dev/outputs.tf environments/prod/outputs.tf
cp environments/dev/providers.tf environments/prod/providers.tf
cp environments/dev/versions.tf environments/prod/versions.tf
```

### 2. Tạo terraform.tfvars cho prod

```hcl
# environments/prod/terraform.tfvars

project_name = "three-tier"
environment  = "prod"
aws_region   = "ap-southeast-1"

# Network
vpc_cidr            = "10.1.0.0/16"  # CIDR khác dev
availability_zones  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
app_subnets_cidrs   = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
db_subnets_cidrs    = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

# EC2 — production sizing
ami_id        = "ami-0543dbdaf4e114be7"
instance_type = "t3.medium"

# Auto Scaling — min 2 instance
desired_capacity = 3
min_size         = 2
max_size         = 10

# RDS — production sizing + Multi-AZ
db_instance_class     = "db.t3.medium"
allocated_storage     = 50
max_allocated_storage = 500
database_name         = "appdb"
database_username     = "admin"
database_password     = ""  # Từ GitHub Secret
multi_az              = true  # BẮT BUỘC cho production

# Monitoring
sns_email                   = "oncall@company.com"
asg_cpu_high_threshold      = 70
asg_cpu_low_threshold       = 20
rds_cpu_high_threshold      = 70
rds_free_storage_threshold  = 10737418240  # 10 GB
rds_connections_threshold   = 500
alb_5xx_threshold           = 5
alb_response_time_threshold = 1
log_retention_days          = 30
```

### 3. Cập nhật module RDS cho production

Trong `environments/prod/main.tf`, thêm vào module `rds`:

```hcl
module "rds" {
  # ...
  multi_az            = true
  deletion_protection = true   # Thêm variable này
  skip_final_snapshot = false  # Lưu snapshot khi destroy
}
```

---

## Checklist trước khi deploy production

- [ ] `multi_az = true` trong module RDS
- [ ] `deletion_protection = true` trong module RDS
- [ ] `skip_final_snapshot = false` trong module RDS
- [ ] HTTPS Listener và ACM certificate được cấu hình trong module ALB
- [ ] ALB access logs bật và trỏ vào S3 bucket
- [ ] CloudTrail được tạo (OPA `compliance.rego` sẽ deny nếu thiếu)
- [ ] GitHub Environment `production` có protection rules: required reviewers
- [ ] Slack webhook cấu hình để nhận thông báo deploy
- [ ] `sns_email` điền đúng email team on-call
- [ ] `log_retention_days` đặt ≥ 30 ngày

---

## CI/CD cho Production

Production không tự động deploy. Chỉ deploy qua `workflow_dispatch` với action `apply`, và yêu cầu xác nhận qua GitHub Environment `production`:

```
workflow_dispatch (action=apply)
    │
    ▼
  plan → OPA gate
    │
    ▼ (pass)
  Waiting for approval (GitHub Environment: production)
    │
    ▼ (approved)
  terraform apply
```
