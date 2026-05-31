# Hướng dẫn chạy CI/CD Pipeline

## Mục lục

1. [Điều kiện tiên quyết](#1-dieu-kien-tien-quyet)
2. [Bước 1 — Tạo IAM User trên AWS](#buoc-1--tao-iam-user-tren-aws)
3. [Bước 2 — Tạo S3 Bucket lưu Terraform State](#buoc-2--tao-s3-bucket-luu-terraform-state)
4. [Bước 3 — Cấu hình GitHub Secrets](#buoc-3--cau-hinh-github-secrets)
5. [Bước 4 — Cấu hình GitHub Environments](#buoc-4--cau-hinh-github-environments)
6. [Bước 5 — Kiểm tra cấu trúc file bắt buộc](#buoc-5--kiem-tra-cau-truc-file-bat-buoc)
7. [Cách chạy terraform-ci.yml](#cach-chay-terraform-ciyml)
8. [Cách chạy terraform-cd.yml](#cach-chay-terraform-cdyml)
9. [Cách chạy check-scan.yml](#cach-chay-check-scanyml)
10. [Xử lý lỗi thường gặp](#xu-ly-loi-thuong-gap)

---

## 1. Điều kiện tiên quyết

Trước khi chạy bất kỳ workflow nào, cần chuẩn bị đủ các mục sau:

| Mục | Bắt buộc | Dùng bởi |
|-----|----------|----------|
| AWS Account + IAM User | Bắt buộc | terraform-cd, check-scan |
| S3 Bucket cho Terraform state | Bắt buộc | terraform-cd, check-scan |
| GitHub Secrets (5 biến) | Bắt buộc | Cả 3 workflow |
| GitHub Environments | Bắt buộc | terraform-cd |
| File `terraform.tfvars` trong `environments/dev/` | Bắt buộc | terraform-cd, check-scan |
| Slack Webhook URL | Tùy chọn | Cả 3 workflow |

---

## Bước 1 — Tạo IAM User trên AWS

CI/CD cần một IAM User với quyền đủ để tạo toàn bộ hạ tầng three-tier.

### 1.1 Tạo IAM User

```
AWS Console -> IAM -> Users -> Create user
User name: github-actions-dev
Access type: Programmatic access (Access key)
```

### 1.2 Gán IAM Policy

Tạo một custom policy với tên `GitHubActionsDeployPolicy` và dán nội dung sau:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Permissions",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSPermissions",
      "Effect": "Allow",
      "Action": [
        "rds:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ElasticLoadBalancingPermissions",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AutoScalingPermissions",
      "Effect": "Allow",
      "Action": [
        "autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:GetRole",
        "iam:PassRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:ListInstanceProfilesForRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3StatePermissions",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:GetBucketAcl",
        "s3:GetBucketLogging",
        "s3:GetBucketPolicy",
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-BUCKET-NAME",
        "arn:aws:s3:::YOUR-BUCKET-NAME/*"
      ]
    },
    {
      "Sid": "CloudWatchPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudTrailPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudtrail:*"
      ],
      "Resource": "*"
    }
  ]
}
```

> Thay `YOUR-BUCKET-NAME` bằng tên S3 bucket sẽ tạo ở Bước 2.

### 1.3 Lấy Access Key

```
IAM -> Users -> github-actions-dev -> Security credentials
-> Create access key -> Application running outside AWS
```

Lưu lại:
- `Access key ID` → sẽ dùng cho secret `AWS_ACCESS_KEY_ID`
- `Secret access key` → sẽ dùng cho secret `AWS_SECRET_ACCESS_KEY`

---

## Bước 2 — Tạo S3 Bucket lưu Terraform State

Terraform cần một S3 bucket để lưu state file. Bucket này phải tạo **trước** khi chạy CI/CD.

### 2.1 Tạo bucket bằng AWS CLI

```bash
# Thay YOUR-BUCKET-NAME bằng tên bucket của bạn (phải unique toàn cầu)
# Ví dụ: three-tier-tfstate-dev-2024

aws s3api create-bucket \
  --bucket YOUR-BUCKET-NAME \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

# Bat versioning (quan trong - de rollback state neu can)
aws s3api put-bucket-versioning \
  --bucket YOUR-BUCKET-NAME \
  --versioning-configuration Status=Enabled

# Bat encryption
aws s3api put-bucket-encryption \
  --bucket YOUR-BUCKET-NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket YOUR-BUCKET-NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### 2.2 Tạo DynamoDB Table cho State Locking (khuyến nghị)

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

### 2.3 Cấu hình backend.tf trong environments/dev/

```hcl
# environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "YOUR-BUCKET-NAME"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

---

## Bước 3 — Cấu hình GitHub Secrets

Vào repository GitHub:

```
Settings -> Secrets and variables -> Actions -> New repository secret
```

Tạo đủ 5 secrets sau:

| Secret Name | Giá trị | Bắt buộc |
|-------------|---------|----------|
| `AWS_ACCESS_KEY_ID` | Access key ID lấy ở Bước 1.3 | Bắt buộc |
| `AWS_SECRET_ACCESS_KEY` | Secret access key lấy ở Bước 1.3 | Bắt buộc |
| `BUCKET_TF_STATE` | Tên S3 bucket lấy ở Bước 2 | Bắt buộc |
| `DB_PASSWORD` | Password cho RDS (ít nhất 8 ký tự) | Bắt buộc |
| `SLACK_WEBHOOK_URL` | Webhook URL từ Slack App | Tùy chọn |

### Tạo Slack Webhook (nếu muốn nhận thông báo)

```
Slack -> Apps -> Incoming Webhooks -> Add to Slack
-> Chọn channel -> Copy Webhook URL
```

---

## Bước 4 — Cấu hình GitHub Environments

Environments dùng để kiểm soát việc deploy (có thể thêm manual approval).

```
GitHub Repo -> Settings -> Environments -> New environment
```

Tạo 2 environments:

**Environment `development`**
```
Name: development
Protection rules: (không cần reviewer cho dev)
```

**Environment `production`** (dùng cho sau khi mở rộng sang prod)
```
Name: production
Protection rules:
  - Required reviewers: [thêm tên reviewer]
  - Wait timer: 0 minutes
```

> Hiện tại chỉ deploy dev, production environment có thể tạo trước để sẵn sàng.

---

## Bước 5 — Kiểm tra cấu trúc file bắt buộc

Trước khi push code, kiểm tra đủ các file sau trong repository:

```
AWS-Three-Tier-Architecture/
│
├── .github/
│   └── workflows/
│       ├── terraform-ci.yml       <- File vừa tạo
│       ├── terraform-cd.yml       <- File vừa tạo
│       └── check-scan.yml         <- File vừa tạo
│
├── environments/
│   └── dev/
│       ├── backend.tf             <- Cau hinh S3 backend (Buoc 2.3)
│       ├── main.tf                <- Goi cac module
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── versions.tf
│       └── terraform.tfvars       <- Gia tri bien thuc te (QUAN TRONG)
│
├── modules/
│   ├── vpc/
│   ├── security-group/
│   ├── alb/
│   ├── ec2/
│   ├── autoscaling/
│   ├── rds/
│   └── monitoring/
│
└── policies/
    ├── security.rego              <- File vua tao
    ├── networking.rego            <- File vua tao
    └── compliance.rego            <- File vua tao
```

### File terraform.tfvars mẫu

```hcl
# environments/dev/terraform.tfvars

# Thong tin chung
environment = "dev"
project     = "three-tier-arch"
aws_region  = "ap-southeast-1"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
db_subnet_cidrs      = ["10.0.21.0/24", "10.0.22.0/24"]

# EC2 Web Tier
web_instance_type = "t3.micro"
web_ami_id        = "ami-0c02fb55956c7d316"   # Amazon Linux 2, ap-southeast-1

# EC2 App Tier
app_instance_type = "t3.micro"
app_ami_id        = "ami-0c02fb55956c7d316"

# RDS
db_instance_class   = "db.t3.micro"
db_engine           = "mysql"
db_engine_version   = "8.0"
db_name             = "appdb"
db_username         = "admin"
# db_password duoc truyen qua TF_VAR_db_password tu GitHub Secret

# Tags
tags = {
  Environment = "dev"
  Project     = "three-tier-arch"
  ManagedBy   = "Terraform"
}
```

---

## Cách chạy terraform-ci.yml

File này chạy **tự động**, không cần thao tác thủ công.

### Khi nào tự động chạy

```
Push code lên nhánh develop   ->  CI chạy ngay
Push code lên nhánh feature/* ->  CI chạy ngay (SOFT_FAIL=true, lỗi scan không block)
Tạo Pull Request vào develop  ->  CI chạy và comment kết quả lên PR
```

### Luồng chạy chi tiết

```
[Push/PR]
    |
    v
validate (fmt check + init -backend=false + validate)
    |
    +------------------+------------------+
    v                  v                  v
 tflint             tfsec             checkov
(AWS ruleset)   (IaC security)   (CIS/NIST scan)
    |                  |                  |
    +------------------+------------------+
                       |
                       v
                  ci-summary
         (comment PR + Slack notify)
```

### Xem kết quả

- **GitHub Actions tab**: xem log chi tiết từng step
- **Pull Request**: 5 comment tự động (validate, tflint, checkov, tfsec, summary)
- **Security tab** (GitHub): kết quả Checkov dưới dạng SARIF
- **Artifacts**: tải `tflint-report.json`, `checkov-report` về xem offline

---

## Cách chạy terraform-cd.yml

### Trường hợp 1 — Auto deploy (push lên develop)

```bash
git checkout develop
git add .
git commit -m "feat: add vpc module"
git push origin develop
```

Sau khi push, GitHub Actions tự động:

```
push len develop
    |
    v
plan (terraform plan + export JSON)
    |
    v
opa-gate (kiem tra 3 policy file)
    |           |
  FAIL         PASS
    |           |
  Stop         v
           deploy (terraform apply)
               |
               v
           notify Slack
```

### Trường hợp 2 — Chạy thủ công (workflow_dispatch)

```
GitHub Repo -> Actions -> Terraform CD -> Run workflow
```

Chọn `action`:

| action | Kết quả |
|--------|---------|
| `plan` | Chỉ chạy terraform plan, xem trước thay đổi, không apply |
| `apply` | plan -> OPA gate -> apply |
| `destroy` | Xóa toàn bộ hạ tầng dev |

**Quan trọng với `destroy`**: workflow sẽ yêu cầu xác nhận qua GitHub Environment approval trước khi thực sự xóa.

### Xem kết quả plan

```
Actions -> Terraform CD -> [run cụ thể] -> plan job -> Step Summary
```

Nội dung plan được in đầy đủ trong Step Summary, bao gồm số resource sẽ create/update/destroy.

### Xem kết quả OPA

```
Actions -> Terraform CD -> [run cụ thể] -> opa-gate job
```

Mỗi step OPA in ra:
```
# Nếu pass:
Security: PASS (0 violations)

# Nếu fail:
--- Security violations: 2 ---
  [DENY] RDS instance 'module.rds.aws_db_instance.main': storage_encrypted phai la true
  [DENY] Security Group Rule '...': SSH (port 22) khong duoc mo ra internet
```

---

## Cách chạy check-scan.yml

### Trường hợp 1 — Tự động (hàng ngày 2:00 AM GMT+7)

Không cần làm gì. Workflow tự chạy theo cron `0 19 * * *` (19:00 UTC = 02:00 GMT+7).

### Trường hợp 2 — Chạy thủ công

```
GitHub Repo -> Actions -> Security and Compliance Scan -> Run workflow
```

Chọn `scan_type`:

| scan_type | Chạy gì |
|-----------|---------|
| `all` | OPA full scan + tfsec deep |
| `opa-only` | Chỉ OPA với plan JSON mới nhất |
| `tfsec-only` | Chỉ tfsec deep scan |

### Xem báo cáo

```
Actions -> [run cụ thể] -> Summary tab
```

Step Summary hiển thị bảng tổng hợp:

```
## Security and Compliance Scan Summary - DEV

Scan date: 2024-01-15 19:00 UTC

### OPA Policy Results
| Policy     | Deny | Warn |
|------------|------|------|
| Security   |  0   |  2   |
| Networking |  0   |  1   |
| Compliance |  0   |  3   |

### tfsec Results
Issues found: 5
```

Tải artifact để xem chi tiết:
```
Actions -> [run cụ thể] -> Artifacts
  - opa-full-report    (opa-results.json)
  - tfsec-deep-report  (tfsec-report.json)
```

---

## Xử lý lỗi thường gặp

### Lỗi 1: `Error: No valid credential sources found`

```
Nguyên nhân : GitHub Secret AWS_ACCESS_KEY_ID hoặc AWS_SECRET_ACCESS_KEY sai/thiếu
Cách fix    : Settings -> Secrets -> Kiểm tra lại 2 secret này
              Đảm bảo IAM User còn active và Access Key chưa bị disable
```

### Lỗi 2: `Error: Failed to get existing workspaces: S3 bucket does not exist`

```
Nguyên nhân : Bucket trong BUCKET_TF_STATE chưa tồn tại hoặc tên sai
Cách fix    : Chạy lại Bước 2 để tạo bucket
              Kiểm tra tên bucket trong secret khớp với backend.tf
```

### Lỗi 3: `terraform fmt -check failed`

```
Nguyên nhân : Code Terraform chưa được format đúng chuẩn
Cách fix    : Chạy local trước khi push:
              cd environments/dev && terraform fmt -recursive
```

### Lỗi 4: OPA gate fail với violation

```
Nguyên nhân : Infrastructure code vi phạm policy trong policies/*.rego
Cách fix    : Đọc thông báo [DENY] trong log để biết resource nào vi phạm
              Sửa lại Terraform code theo yêu cầu của policy
              Ví dụ: thêm storage_encrypted = true vào aws_db_instance
```

### Lỗi 5: `TFLint: Failed to initialize plugins`

```
Nguyên nhân : Network timeout khi download AWS ruleset
Cách fix    : Re-run job (thường là lỗi tạm thời)
              Hoặc commit file .tflint.hcl vào repo thay vì generate inline
```

### Lỗi 6: Checkov fail nhưng muốn bỏ qua một số check

```
Nguyên nhân : Một số check CIS không áp dụng cho môi trường dev
Cách fix    : Thêm skip_check vào checkov-action trong terraform-ci.yml
              Ví dụ:
                skip_check: CKV_AWS_144,CKV_AWS_117
              
              Hoặc thêm comment inline vào Terraform:
                #checkov:skip=CKV_AWS_144: Dev environment, no cross-region replication needed
```

### Lỗi 7: `Plan JSON exported but OPA returns no results`

```
Nguyên nhân : Package name trong rego file không khớp với query path
Cách fix    : Kiểm tra dòng đầu của từng file:
              security.rego   -> package terraform.security
              networking.rego -> package terraform.networking
              compliance.rego -> package terraform.compliance
              
              Query trong workflow phải là:
              data.terraform.security.deny
              data.terraform.networking.deny
              data.terraform.compliance.deny
```

---

## Tóm tắt checklist trước khi chạy lần đầu

```
[ ] IAM User tạo xong, có Access Key + Secret Key
[ ] IAM Policy gán đủ quyền cho IAM User
[ ] S3 bucket tạo xong, versioning + encryption đã bật
[ ] DynamoDB table tạo xong (cho state locking)
[ ] backend.tf trong environments/dev/ trỏ đúng bucket
[ ] terraform.tfvars trong environments/dev/ có đủ biến
[ ] 5 GitHub Secrets đã cấu hình (4 bắt buộc + 1 Slack)
[ ] 2 GitHub Environments đã tạo (development, production)
[ ] 6 file CI/CD đã commit vào đúng đường dẫn
[ ] Chạy thử local: cd environments/dev && terraform init && terraform validate
```
