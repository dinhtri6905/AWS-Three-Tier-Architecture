# Module: RDS

Module tạo Amazon RDS MySQL 8.0 cho Data tier, hoàn toàn cô lập trong private subnet, bật mã hóa, backup tự động và không có public access.

---

## Tài nguyên được tạo

| Resource | Mô tả |
|----------|-------|
| `aws_db_subnet_group` | DB Subnet Group — nhóm các private DB subnet |
| `aws_db_instance` | RDS MySQL 8.0 instance |

---

## Cấu hình bảo mật (bắt buộc theo OPA policy)

| Thuộc tính | Giá trị | OPA Rule |
|-----------|---------|----------|
| `publicly_accessible` | `false` | `security.rego` → deny |
| `storage_encrypted` | `true` | `security.rego` → deny nếu false |
| `backup_retention_period` | `7` ngày | `security.rego` → deny nếu < 7 |
| `db_subnet_group_name` | bắt buộc có | `networking.rego` → deny nếu thiếu |
| `storage_type` | `gp3` | Hiệu năng tốt hơn gp2 |
| `auto_minor_version_upgrade` | `true` | Tự động vá bảo mật |
| `copy_tags_to_snapshot` | `true` | Tags được sao chép vào snapshot |

---

## Cấu hình storage

| Thuộc tính | Giá trị mặc định | Mô tả |
|-----------|------------------|-------|
| `storage_type` | `gp3` | General Purpose SSD thế hệ 3 |
| `allocated_storage` | `20` GB | Dung lượng khởi đầu |
| `max_allocated_storage` | `100` GB | Giới hạn tối đa khi autoscale storage |

Storage Autoscaling tự động mở rộng khi dung lượng còn lại dưới 10% hoặc dưới 5 GB.

---

## Variables

| Tên | Kiểu | Mặc định | Mô tả |
|-----|------|----------|-------|
| `project_name` | `string` | — | Tên project |
| `environment` | `string` | — | Môi trường deploy |
| `db_subnet_ids` | `list(string)` | — | DB Subnet IDs — output từ module `vpc` |
| `rds_security_group_id` | `string` | — | SG ID — output từ module `security-group` |
| `db_instance_class` | `string` | `db.t3.micro` | Loại RDS instance |
| `allocated_storage` | `number` | `20` | Dung lượng ban đầu (GB) |
| `max_allocated_storage` | `number` | `100` | Dung lượng tối đa autoscale (GB) |
| `database_name` | `string` | — | Tên database được tạo sẵn |
| `database_username` | `string` | — | Username master |
| `database_password` | `string` | — | Password master (**sensitive**) |
| `multi_az` | `bool` | `false` | Bật Multi-AZ cho HA |

---

## Outputs

| Tên | Mô tả |
|-----|-------|
| `rds_instance_id` | Identifier của RDS instance — input cho module `monitoring` |
| `rds_instance_arn` | ARN của RDS instance |
| `rds_endpoint` | Endpoint đầy đủ (`host:port`) để kết nối |
| `rds_address` | Hostname của RDS (không có port) |
| `rds_port` | Port MySQL (3306) |
| `database_name` | Tên database |
| `database_username` | Username master (**sensitive**) |

---

## Cách sử dụng

```hcl
module "rds" {
  source = "../../modules/rds"

  project_name = "three-tier"
  environment  = "dev"

  db_subnet_ids         = module.vpc.db_subnet_ids
  rds_security_group_id = module.security-group.rds_security_group_id

  db_instance_class     = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100

  database_name     = "appdb"
  database_username = "admin"
  database_password = var.database_password  # Từ GitHub Secret

  multi_az = false  # true cho production
}
```

Kết nối từ EC2 App tier:

```bash
mysql -h <rds_address> -u admin -p appdb
```

---

## Lưu ý

- **Password**: Không hardcode password trong code. Truyền qua biến `database_password` và cấu hình qua GitHub Secret `DB_PASSWORD`.
- **Multi-AZ**: `multi_az = false` cho dev/lab để giảm chi phí. Production bắt buộc `multi_az = true` — OPA sẽ warn nếu false.
- **Deletion protection**: Tắt cho lab (`skip_final_snapshot = true`, `deletion_protection = false`). Production nên bật cả hai.
- **Port bảo vệ**: RDS SG chỉ mở port 3306 từ EC2 SG — không thể kết nối trực tiếp từ máy cá nhân hoặc internet.
- **Encrypt**: `storage_encrypted = true` sử dụng AWS managed key mặc định. Production có thể dùng KMS Customer Managed Key.
