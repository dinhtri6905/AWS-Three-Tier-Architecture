# Environment: Dev

Cấu hình Terraform cho môi trường **Development** của kiến trúc ba tầng AWS. Môi trường dev được tối ưu cho chi phí thấp và tốc độ triển khai nhanh trong khi vẫn giữ đầy đủ cấu trúc bảo mật của production.

---

## Cấu trúc file

```
environments/dev/
├── backend.tf          # Remote state: S3 + DynamoDB lock
├── main.tf             # Gọi các module theo thứ tự dependency
├── variables.tf        # Khai báo tất cả biến với giá trị mặc định dev
├── outputs.tf          # Output quan trọng sau khi deploy
├── providers.tf        # AWS provider, region ap-southeast-1
├── versions.tf         # Phiên bản Terraform và provider tối thiểu
└── terraform.tfvars    # Giá trị biến thực tế (không commit lên git)
```

---

## Modules được gọi

```
main.tf
├── module "vpc"            → modules/vpc
├── module "security-group" → modules/security-group
├── module "s3"             → modules/s3
├── module "alb"            → modules/alb
├── module "ec2"            → modules/ec2
├── module "autoscaling"    → modules/autoscaling
├── module "rds"            → modules/rds
└── module "monitoring"     → modules/monitoring
```

Thứ tự dependency: `vpc` → `security-group` + `s3` → `alb` → `ec2` + `autoscaling` → `rds` → `monitoring`

---

## Remote State Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "<BUCKET_TF_STATE>"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

State file của môi trường dev được lưu tại: `s3://<bucket>/dev/terraform.tfstate`

---

## Giá trị mặc định cho Dev

| Biến | Giá trị mặc định | Ghi chú |
|------|-----------------|---------|
| `environment` | `dev` | |
| `aws_region` | `ap-southeast-1` | Singapore |
| `vpc_cidr` | `10.0.0.0/16` | |
| `availability_zones` | `[a, b, c]` | 3 AZ |
| `instance_type` | `t3.micro` | Free tier eligible |
| `db_instance_class` | `db.t3.micro` | Nhỏ nhất, giảm chi phí |
| `multi_az` | `false` | Tắt Multi-AZ để giảm chi phí dev |
| `desired_capacity` | `2` | |
| `min_size` | `1` | |
| `max_size` | `4` | |
| `allocated_storage` | `20` GB | |
| `max_allocated_storage` | `100` GB | |
| `log_retention_days` | `7` | |

---

## Cấu hình terraform.tfvars

Tạo file `environments/dev/terraform.tfvars` với nội dung:

```hcl
# Project
project_name = "three-tier"
environment  = "dev"
aws_region   = "ap-southeast-1"

# Network
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
app_subnets_cidrs   = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
db_subnets_cidrs    = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# EC2
ami_id        = "ami-0543dbdaf4e114be7"  # Amazon Linux 2, ap-southeast-1
instance_type = "t3.micro"

# Auto Scaling
desired_capacity = 2
min_size         = 1
max_size         = 4

# RDS
db_instance_class     = "db.t3.micro"
allocated_storage     = 20
max_allocated_storage = 100
database_name         = "appdb"
database_username     = "admin"
database_password     = ""  # Truyền qua GitHub Secret DB_PASSWORD
multi_az              = false

# Monitoring
sns_email                   = ""  # Email nhận alert
asg_cpu_high_threshold      = 80
asg_cpu_low_threshold       = 20
rds_cpu_high_threshold      = 80
rds_free_storage_threshold  = 5368709120  # 5 GB
rds_connections_threshold   = 100
alb_5xx_threshold           = 10
alb_response_time_threshold = 2
log_retention_days          = 7
```

> **Không commit file `terraform.tfvars`** — file này được thêm vào `.gitignore`.

---

## Deploy thủ công

```bash
cd environments/dev

# 1. Khởi tạo backend
terraform init

# 2. Kiểm tra cú pháp
terraform validate
terraform fmt -check 
# terraform fmt -recursive

# 3. Xem trước thay đổi
terraform plan -var="database_password=<password>"

# 4. Apply
terraform apply -var="database_password=<password>"
```

---

## Deploy qua CI/CD

Merge vào nhánh `develop` sẽ tự động trigger `terraform-cd.yml`:

```
develop branch push
    │
    ▼
  plan → OPA gate (security + networking + compliance)
    │
    ▼ (pass)
  terraform apply
```

---

## Outputs quan trọng

Sau khi deploy, các output sau sẽ hiển thị:

```bash
terraform output alb_dns_name       # URL truy cập ứng dụng
terraform output rds_endpoint       # Endpoint kết nối RDS
terraform output dashboard_url      # URL CloudWatch Dashboard
```

---

## Destroy

```bash
# Thủ công
terraform destroy -var="database_password=<password>"

# Qua CI/CD (workflow_dispatch với action=destroy)
# → Yêu cầu xác nhận qua GitHub Environment protection rules
```

> **Cảnh báo**: Destroy sẽ xóa toàn bộ hạ tầng bao gồm RDS (`skip_final_snapshot = true`). Đảm bảo đã backup dữ liệu trước khi destroy.
