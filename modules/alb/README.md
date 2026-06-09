# Module: Application Load Balancer (ALB)

Module tạo Application Load Balancer internet-facing, Target Group và HTTP Listener cho Web tier của kiến trúc ba tầng.

---

## Tài nguyên được tạo

| Resource | Mô tả |
|----------|-------|
| `aws_lb` | Application Load Balancer internet-facing, multi-AZ |
| `aws_lb_target_group` | Target Group nhận traffic từ ALB, health check mỗi 30 giây |
| `aws_lb_listener` | HTTP Listener port 80, forward đến Target Group |

---

## Kiến trúc

```
Internet
    │ HTTP:80 / HTTPS:443
    ▼
┌────────────────────────────────────────────┐
│       Application Load Balancer            │
│  internet-facing · multi-AZ · drop headers │
│  Public Subnet AZ-a | AZ-b | AZ-c         │
└──────────────────┬─────────────────────────┘
                   │ HTTP:80
                   ▼
        ┌─────────────────────┐
        │    Target Group     │
        │  health check: /    │
        │  interval: 30s      │
        │  threshold: 2/2     │
        └──────────┬──────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
   EC2 AZ-a              EC2 AZ-b ...
```

---

## Cấu hình chi tiết

### Application Load Balancer

| Thuộc tính | Giá trị | Ghi chú |
|-----------|---------|---------|
| `internal` | `false` | Internet-facing |
| `load_balancer_type` | `application` | Layer 7 |
| `drop_invalid_header_fields` | `true` | Bảo mật — CKV_AWS_131 |
| `enable_deletion_protection` | `false` | Lab environment |
| `subnets` | Public subnets | Bắt buộc ≥ 2 AZ (OPA check) |

### Target Group

| Thuộc tính | Giá trị |
|-----------|---------|
| `port` | 80 |
| `protocol` | HTTP |
| `target_type` | instance |
| `health_check.path` | `/` |
| `health_check.interval` | 30 giây |
| `healthy_threshold` | 2 lần liên tiếp |
| `unhealthy_threshold` | 2 lần liên tiếp |
| `health_check.matcher` | `200` |

### HTTP Listener

| Thuộc tính | Giá trị |
|-----------|---------|
| `port` | 80 |
| `protocol` | HTTP |
| `default_action` | Forward → Target Group |

---

## Variables

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `project_name` | `string` | Tên project |
| `environment` | `string` | Môi trường deploy (`dev`, `prod`) |
| `vpc_id` | `string` | ID của VPC |
| `public_subnet_ids` | `list(string)` | ID các Public Subnet (≥ 2 subnet, ≥ 2 AZ) |
| `alb_security_group_id` | `string` | SG ID cho ALB — output từ module `security-group` |
| `alb_logs_id` | `string` | ID S3 bucket lưu access log — output từ module `s3` |

---

## Outputs

| Tên | Mô tả |
|-----|-------|
| `alb_id` | ID của ALB |
| `alb_arn` | ARN của ALB |
| `alb_arn_suffix` | ARN suffix — dùng làm dimension cho CloudWatch |
| `alb_dns_name` | DNS name để truy cập ứng dụng |
| `alb_zone_id` | Zone ID của ALB (dùng cho Route 53 alias) |
| `target_group_arn` | ARN Target Group — input cho module `ec2`, `autoscaling` |
| `target_group_name` | Tên Target Group |
| `target_group_arn_suffix` | ARN suffix Target Group — dùng cho CloudWatch |
| `http_listener_arn` | ARN HTTP Listener |

---

## Cách sử dụng

```hcl
module "alb" {
  source = "../../modules/alb"

  project_name = "three-tier"
  environment  = "dev"

  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security-group.alb_security_group_id
  alb_logs_id           = module.s3.alb_logs_id
}
```

Sau khi deploy, truy cập ứng dụng qua:

```bash
terraform output -raw alb_dns_name
# → three-tier-dev-alb-xxxxxxxxx.ap-southeast-1.elb.amazonaws.com
```

---

## Lưu ý

- **Multi-AZ**: OPA policy (`networking.rego`) sẽ deny nếu ALB deploy trên ít hơn 2 subnet — cần truyền ít nhất 2 public subnet từ 2 AZ khác nhau.
- **HTTPS**: Listener hiện dùng HTTP (port 80). Production nên thêm HTTPS Listener với ACM certificate và redirect HTTP → HTTPS.
- **Access logs**: Phần `access_logs` đã được chuẩn bị nhưng comment out. Uncomment và truyền `alb_logs_id` để bật trong production.
- **WAF**: `CKV2_AWS_28` bị skip. Production nên gắn AWS WAF WebACL vào ALB.
