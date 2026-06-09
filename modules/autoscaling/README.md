# Module: Auto Scaling

Module tạo Launch Template và Auto Scaling Group (ASG) cho Application tier, cho phép tự động scale số lượng EC2 instance theo tải, trải đều trên nhiều Availability Zone.

---

## Tài nguyên được tạo

| Resource | Mô tả |
|----------|-------|
| `aws_launch_template` | Template cấu hình instance (AMI, type, SG, user data, IMDSv2) |
| `aws_autoscaling_group` | ASG quản lý vòng đời instance, health check qua ALB |

---

## Kiến trúc

```
┌──────────────────────────────────────────────────┐
│           Auto Scaling Group                     │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │         Launch Template                  │    │
│  │  AMI · instance_type · IMDSv2 · user_data│    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│   min_size ≤ desired_capacity ≤ max_size         │
│                                                  │
│   AZ-a subnet   AZ-b subnet   AZ-c subnet        │
│  [instance]    [instance]    [instance]          │
└─────────────────────┬────────────────────────────┘
                      │ health_check_type = ELB
                      ▼
              ALB Target Group
```

---

## Cấu hình Launch Template

| Thuộc tính | Giá trị | Ghi chú |
|-----------|---------|---------|
| `http_tokens` | `required` | IMDSv2 bắt buộc — OPA `security.rego` deny nếu vi phạm |
| `http_endpoint` | `enabled` | IMDS endpoint bật |
| `http_put_response_hop_limit` | `1` | Giới hạn hop cho metadata request |
| Tag instance | `Name`, `Environment`, `Project` | Propagate at launch |

### User Data

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Three-Tier Architecture Auto Scaling Server $(hostname)</h1>" > /var/www/html/index.html
```

---

## Cấu hình Auto Scaling Group

| Thuộc tính | Mô tả |
|-----------|-------|
| `health_check_type` | `ELB` — ASG dùng ALB health check để xác định instance healthy |
| `health_check_grace_period` | 300 giây — chờ instance khởi động trước khi bắt đầu check |
| `vpc_zone_identifier` | App private subnet IDs — trải đều qua AZ |
| `launch_template.version` | `$Latest` — dùng version mới nhất |
| `lifecycle.create_before_destroy` | `true` — không có downtime khi thay thế instance |

---

## Variables

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `project_name` | `string` | Tên project |
| `environment` | `string` | Môi trường deploy (`dev`, `prod`) |
| `ami_id` | `string` | AMI ID cho Launch Template |
| `instance_type` | `string` | Loại EC2 instance (ví dụ: `t3.micro`) |
| `app_security_group_id` | `string` | SG ID — output từ module `security-group` |
| `app_subnet_ids` | `list(string)` | App Subnet IDs — output từ module `vpc` |
| `target_group_arn` | `string` | ALB Target Group ARN — output từ module `alb` |
| `desired_capacity` | `number` | Số instance mong muốn |
| `min_size` | `number` | Số instance tối thiểu |
| `max_size` | `number` | Số instance tối đa |

---

## Outputs

| Tên | Mô tả |
|-----|-------|
| `autoscaling_group_name` | Tên ASG — input cho module `monitoring` |
| `autoscaling_group_arn` | ARN ASG |
| `launch_template_id` | ID Launch Template |
| `launch_template_latest_version` | Version mới nhất của Launch Template |

---

## Cách sử dụng

```hcl
module "autoscaling" {
  source = "../../modules/autoscaling"

  project_name = "three-tier"
  environment  = "dev"

  ami_id                = "ami-0543dbdaf4e114be7"
  instance_type         = "t3.micro"
  app_security_group_id = module.security-group.app_security_group_id
  app_subnet_ids        = module.vpc.app_subnet_ids
  target_group_arn      = module.alb.target_group_arn

  desired_capacity = 2
  min_size         = 1
  max_size         = 4
}
```

---

## Lưu ý

- **OPA compliance**: `security.rego` sẽ deny nếu Launch Template không có `http_tokens = "required"` (IMDSv2).
- **OPA warning**: `compliance.rego` sẽ warn nếu ASG không trải trên ít nhất 2 AZ — đảm bảo `app_subnet_ids` có subnet từ ≥ 2 AZ.
- **Scale policy**: Module này không tạo scaling policy. Để auto-scale theo CPU, cần thêm `aws_autoscaling_policy` và gắn với CloudWatch alarm từ module `monitoring`.
- **ELB health check**: ASG dùng ALB health check thay vì EC2 health check — instance sẽ bị terminate nếu ALB báo unhealthy.
