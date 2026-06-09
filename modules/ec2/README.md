# Module: EC2

Module tạo EC2 instances cho Application tier, đặt trong private subnet, cấu hình bảo mật IMDSv2, mã hóa EBS và tự động đăng ký vào ALB Target Group.

---

## Tài nguyên được tạo

| Resource | Số lượng | Mô tả |
|----------|----------|-------|
| `aws_instance` | N (theo số App Subnet) | EC2 application server, 1 instance per AZ |
| `aws_lb_target_group_attachment` | N | Đăng ký từng instance vào ALB Target Group |

---

## Cấu hình bảo mật

| Thuộc tính | Giá trị | Tiêu chuẩn |
|-----------|---------|-----------|
| `associate_public_ip_address` | `false` | Không có public IP |
| `http_tokens` | `required` | IMDSv2 bắt buộc — CKV_AWS_79 |
| `http_endpoint` | `enabled` | IMDS endpoint bật nhưng chỉ IMDSv2 |
| `root_block_device.encrypted` | `true` | Mã hóa EBS root volume — CKV_AWS_8 |
| `ebs_optimized` | `true` | Tối ưu EBS throughput |
| `subnet_id` | App private subnet | Không deploy lên public subnet |

---

## User Data

Khi instance khởi động lần đầu, user data tự động cài đặt và chạy Apache HTTP server:

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Three-Tier Architecture App Server $(hostname)</h1>" > /var/www/html/index.html
```

---

## Variables

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `project_name` | `string` | Tên project |
| `environment` | `string` | Môi trường deploy (`dev`, `prod`) |
| `ami_id` | `string` | AMI ID — khuyến nghị dùng Amazon Linux 2023 |
| `instance_type` | `string` | Loại instance (ví dụ: `t3.micro`) |
| `app_subnet_ids` | `list(string)` | Danh sách App Subnet ID — output từ module `vpc` |
| `app_security_group_id` | `string` | SG ID cho EC2 — output từ module `security-group` |
| `target_group_arn` | `string` | ARN ALB Target Group — output từ module `alb` |

> **AMI gợi ý**: `ami-0543dbdaf4e114be7` (Amazon Linux 2) hoặc `ami-0d105bf3c7d10a264` — kiểm tra AMI mới nhất theo region `ap-southeast-1` trước khi deploy.

---

## Outputs

| Tên | Mô tả |
|-----|-------|
| `instance_ids` | List ID của các EC2 instance |
| `private_ips` | List private IP của từng instance |
| `private_dns` | List private DNS name của từng instance |
| `availability_zones` | List AZ mà các instance được deploy |

---

## Cách sử dụng

```hcl
module "ec2" {
  source = "../../modules/ec2"

  project_name = "three-tier"
  environment  = "dev"

  ami_id        = "ami-0543dbdaf4e114be7"
  instance_type = "t3.micro"

  app_subnet_ids        = module.vpc.app_subnet_ids
  app_security_group_id = module.security-group.app_security_group_id
  target_group_arn      = module.alb.target_group_arn
}
```

---

## Lưu ý

- **EC2 vs ASG**: Module `ec2` tạo các instance static (fixed), còn module `autoscaling` tạo instance dynamic qua Launch Template. Cả hai đều đăng ký vào cùng Target Group. Trong production nên ưu tiên dùng `autoscaling` để có khả năng scale tự động.
- **SSH**: Không có key pair được cấu hình. Truy cập instance qua **AWS Systems Manager Session Manager** (không cần mở port 22).
- **IAM Role**: `CKV2_AWS_41` bị skip. Production nên gắn IAM Instance Profile để cấp quyền SSM, CloudWatch Agent, v.v.
- **Monitoring**: `CKV_AWS_126` bị skip — Detailed Monitoring tính phí thêm, cân nhắc bật cho production.
