# Policies — Policy-as-Code với OPA/Rego

Thư mục `policies/` chứa 3 file Rego được thực thi tự động trong CI/CD pipeline trước khi bất kỳ resource Terraform nào được tạo. Mỗi lần `terraform plan` tạo ra JSON plan, OPA sẽ đánh giá plan đó theo các rule bên dưới.

---

## Tổng quan

```
tfplan.json  (terraform plan -out=plan.tfplan && terraform show -json plan.tfplan)
    │
    ├── security.rego    → data.terraform.security.deny / .warn
    ├── networking.rego  → data.terraform.networking.deny / .warn
    └── compliance.rego  → data.terraform.compliance.deny / .warn
```

**Phân loại kết quả:**
- `deny` — vi phạm nghiêm trọng. Pipeline dừng lại, không apply.
- `warn` — cảnh báo. In ra log nhưng pipeline tiếp tục.

---

## security.rego

Kiểm tra bảo mật theo từng service: EC2, Launch Template, RDS, Security Group, IAM.

### Deny rules

| Rule | Resource | Điều kiện |
|------|----------|-----------|
| IMDSv2 bắt buộc | `aws_instance`, `aws_launch_template` | `http_tokens != "required"` |
| RDS mã hóa | `aws_db_instance` | `storage_encrypted != true` |
| RDS private | `aws_db_instance` | `publicly_accessible != false` |
| RDS backup | `aws_db_instance` | `backup_retention_period < 7` |
| SSH public | `aws_security_group_rule` | port 22 từ `0.0.0.0/0` |
| RDP public | `aws_security_group_rule` | port 3389 từ `0.0.0.0/0` |
| DB port public | `aws_security_group_rule` | port 3306/5432 từ `0.0.0.0/0` |
| All traffic public | `aws_security_group_rule` | `protocol = -1` từ `0.0.0.0/0` |
| IAM wildcard | `aws_iam_policy` | `Action = *` và `Resource = *` |
| IAM user policy | `aws_iam_user_policy` | Bất kỳ user inline policy nào |

### Warn rules

| Rule | Điều kiện |
|------|-----------|
| ALB access logs | `access_logs.enabled != true` |
| RDS deletion protection | `deletion_protection != true` |
| EC2 no key_name | Không có key pair → đảm bảo có SSM |

---

## networking.rego

Kiểm tra cô lập mạng đúng theo từng tier.

### Deny rules

| Rule | Resource | Điều kiện |
|------|----------|-----------|
| VPC DNS | `aws_vpc` | `enable_dns_hostnames` hoặc `enable_dns_support` = false |
| Private subnet no public IP | `aws_subnet` (Tier=app/database) | `map_public_ip_on_launch = true` |
| App EC2 no public IP | `aws_instance` (Tier=app) | `associate_public_ip_address = true` |
| RDS subnet group | `aws_db_instance` | `db_subnet_group_name` trống |
| ALB internet-facing | `aws_lb` (Tier=web) | `internal = true` |
| ALB multi-AZ | `aws_lb` | Ít hơn 2 subnet |
| SG description | `aws_security_group` | `description = "managed by terraform"` |
| DB egress | `aws_security_group_rule` (DB SG) | `protocol = -1` egress ra `0.0.0.0/0` |

### Warn rules

| Rule | Điều kiện |
|------|-----------|
| VPC Flow Logs | Không có `aws_flow_log` trong plan |
| HTTPS Listener | ALB Listener Web tier dùng port 80 thay vì 443 |
| NAT Gateway | Không có `aws_nat_gateway` trong plan |

---

## compliance.rego

Kiểm tra tuân thủ **CIS AWS Foundations Benchmark v1.5.0** và Tagging Policy của tổ chức.

### Deny rules — CIS

| Rule | CIS ID | Resource | Điều kiện |
|------|--------|----------|-----------|
| S3 encryption | 2.1.1 | `aws_s3_bucket` | Không có `server_side_encryption_configuration` |
| S3 versioning | 2.1.2 | `aws_s3_bucket_versioning` | `status != "Enabled"` |
| S3 public access block | 2.1.3 | `aws_s3_bucket_public_access_block` | Thiếu bất kỳ setting nào trong 4 block |
| CloudTrail required | 3.1 | — | Không có `aws_cloudtrail` trong plan |
| CloudTrail log validation | 3.2 | `aws_cloudtrail` | `enable_log_file_validation != true` |
| CloudTrail CloudWatch | 3.4 | `aws_cloudtrail` | Không có `cloud_watch_logs_group_arn` |
| CloudTrail multi-region | 3.5 | `aws_cloudtrail` | `is_multi_region_trail != true` |
| IAM no user policy | 5.1 | `aws_iam_user_policy` | Tồn tại bất kỳ user inline policy |
| IAM no wildcard | 5.2 | `aws_iam_policy` | `Action = *` và `Resource = *` |
| RDS encryption | 5.4 | `aws_db_instance` | `storage_encrypted != true` |

### Deny rules — Tagging Policy

Các resource sau phải có đủ 3 tag: `Environment`, `Project`, `ManagedBy`:

`aws_instance`, `aws_db_instance`, `aws_lb`, `aws_vpc`, `aws_subnet`, `aws_security_group`, `aws_s3_bucket`

### Warn rules

| Rule | CIS | Điều kiện |
|------|-----|-----------|
| S3 access logging | 2.1.4 | Không có access logging |
| CloudWatch unauthorized API alarm | 4.1 | Không có alarm cho unauthorized calls |
| RDS Multi-AZ | — | `multi_az != true` |
| ASG multi-AZ | — | ASG trên ít hơn 2 AZ |

---

## Cách chạy OPA thủ công

```bash
# Cài OPA
brew install opa  # macOS
# hoặc: https://www.openpolicyagent.org/docs/latest/#running-opa

# Tạo plan JSON
cd environments/dev
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Chạy từng policy
opa eval -d ../../policies/security.rego   -i tfplan.json "data.terraform.security.deny"
opa eval -d ../../policies/networking.rego -i tfplan.json "data.terraform.networking.deny"
opa eval -d ../../policies/compliance.rego -i tfplan.json "data.terraform.compliance.deny"

# Xem cả deny và warn
opa eval -d ../../policies/ -i tfplan.json "data.terraform"
```

---

## Cách đọc kết quả OPA

```json
{
  "result": [{
    "expressions": [{
      "value": [
        "RDS instance three-tier-dev-mysql must have storage_encrypted = true",
        "EC2 instance must enforce IMDSv2 (http_tokens = required)"
      ]
    }]
  }]
}
```

Mỗi phần tử trong mảng là một vi phạm. Mảng rỗng `[]` nghĩa là không có vi phạm.

---

## Thêm rule mới

```rego
# Ví dụ: deny nếu EC2 không có tag "Owner"
deny[msg] {
  r := input.resource_changes[_]
  r.type == "aws_instance"
  r.change.actions[_] == "create"
  not r.change.after.tags.Owner
  msg := sprintf("EC2 instance '%s' must have 'Owner' tag", [r.address])
}
```

Thêm rule vào file `.rego` tương ứng và đẩy lên — pipeline sẽ tự động áp dụng lần deploy tiếp theo.
