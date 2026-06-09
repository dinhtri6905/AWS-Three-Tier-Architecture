# Module: S3

Module tạo S3 bucket dùng để lưu trữ access log của Application Load Balancer (ALB), với đầy đủ cấu hình bảo mật: block public access, versioning, mã hóa AES-256 và lifecycle tự động xóa log cũ.

---

## Tài nguyên được tạo

| Resource | Mô tả |
|----------|-------|
| `aws_s3_bucket` | S3 bucket lưu ALB access logs |
| `aws_s3_bucket_public_access_block` | Block toàn bộ public access |
| `aws_s3_bucket_versioning` | Bật versioning |
| `aws_s3_bucket_server_side_encryption_configuration` | Mã hóa AES-256 |
| `aws_s3_bucket_lifecycle_configuration` | Tự động xóa log sau 30 ngày |
| `aws_s3_bucket_policy` | Cho phép ALB service ghi log vào bucket |

---

## Cấu hình bảo mật

| Thuộc tính | Giá trị | Tiêu chuẩn |
|-----------|---------|-----------|
| `block_public_acls` | `true` | CIS 2.1.3 |
| `ignore_public_acls` | `true` | CIS 2.1.3 |
| `block_public_policy` | `true` | CIS 2.1.3 |
| `restrict_public_buckets` | `true` | CIS 2.1.3 |
| `versioning` | `Enabled` | CIS 2.1.2 |
| `sse_algorithm` | `AES256` | CIS 2.1.1 |

---

## Bucket Policy

Bucket policy cho phép service `logdelivery.elasticloadbalancing.amazonaws.com` ghi log vào prefix `AWSLogs/*`:

```json
{
  "Statement": [{
    "Sid": "AWSALBLogs",
    "Effect": "Allow",
    "Principal": { "Service": "logdelivery.elasticloadbalancing.amazonaws.com" },
    "Action": ["s3:PutObject"],
    "Resource": "arn:aws:s3:::bucket-name/AWSLogs/*"
  }]
}
```

---

## Lifecycle Rule

| Rule | Hành động |
|------|-----------|
| `expire_old_logs` | Tự động xóa object sau 30 ngày |

---

## Variables

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `project_name` | `string` | Tên project — dùng để đặt tên bucket |
| `environment` | `string` | Môi trường deploy (`dev`, `prod`) |

Tên bucket được tạo theo pattern: `{project_name}-{environment}-alb-logs`

> **Lưu ý**: Tên S3 bucket phải unique toàn cầu. Nếu bị conflict, thêm suffix vào `project_name` hoặc `environment`.

---

## Outputs

| Tên | Mô tả |
|-----|-------|
| `alb_logs_id` | ID của S3 bucket — input cho module `alb` (khi bật access_logs) |

---

## Cách sử dụng

```hcl
module "s3" {
  source = "../../modules/s3"

  project_name = "three-tier"
  environment  = "dev"
}
```

Sau đó truyền output vào module `alb`:

```hcl
module "alb" {
  source = "../../modules/alb"
  # ...
  alb_logs_id = module.s3.alb_logs_id
}
```

Và uncomment block `access_logs` trong `modules/alb/main.tf`:

```hcl
access_logs {
  bucket  = var.alb_logs_id
  prefix  = "alb"
  enabled = true
}
```

---

## Lưu ý

- **OPA compliance**: `compliance.rego` kiểm tra S3 phải có đủ 4 public access block settings, versioning enabled và server-side encryption — module này đáp ứng tất cả.
- **Access log bucket không self-log**: `CKV_AWS_18` bị skip — bucket lưu log ALB không cần self-logging (sẽ tạo vòng lặp vô tận).
- **KMS encryption**: Hiện dùng AES-256 (AWS managed). Production có thể nâng lên `aws:kms` với Customer Managed Key để kiểm soát chính sách rotate key.
- **Cross-region replication**: `CKV_AWS_144` bị skip cho lab. Production trong môi trường DR (Disaster Recovery) nên bật.
