# Module: Security Group

Module tạo Security Group cho từng tầng theo nguyên tắc **least-privilege** — mỗi tier chỉ nhận đúng traffic cần thiết, từ đúng nguồn, đúng port.

---

## Tài nguyên được tạo

| Resource | Tên | Mô tả |
|----------|-----|-------|
| `aws_security_group` | `alb-sg` | Security Group cho Application Load Balancer |
| `aws_security_group` | `ec2-sg` | Security Group cho EC2 Application Servers |
| `aws_security_group` | `rds-sg` | Security Group cho RDS Database |
| `aws_security_group_rule` | (nhiều rule) | Các rule được tạo tách biệt để tránh circular dependency |

---

## Mô hình traffic

```
Internet
    │ HTTP:80 / HTTPS:443
    ▼
┌─────────────────┐
│    ALB SG       │  ingress: 80, 443 from 0.0.0.0/0
│                 │  egress:  all
└────────┬────────┘
         │ HTTP:80 / HTTPS:443 (source: ALB SG)
         ▼
┌─────────────────┐
│    EC2 SG       │  ingress: 80, 443 from ALB SG only
│                 │  egress:  all (cho NAT Gateway outbound)
└────────┬────────┘
         │ MySQL:3306 (source: EC2 SG)
         ▼
┌─────────────────┐
│    RDS SG       │  ingress: 3306 from EC2 SG only
│                 │  egress:  all
└─────────────────┘
```

---

## Chi tiết từng Security Group

### ALB Security Group

| Direction | Port | Protocol | Source | Mục đích |
|-----------|------|----------|--------|----------|
| Ingress | 80 | TCP | `0.0.0.0/0` | Nhận HTTP từ internet |
| Ingress | 443 | TCP | `0.0.0.0/0` | Nhận HTTPS từ internet |
| Egress | All | All | `0.0.0.0/0` | Forward đến EC2 |

### EC2 Security Group

| Direction | Port | Protocol | Source | Mục đích |
|-----------|------|----------|--------|----------|
| Ingress | 80 | TCP | ALB SG | Nhận HTTP từ ALB |
| Ingress | 443 | TCP | ALB SG | Nhận HTTPS từ ALB |
| Egress | All | All | `0.0.0.0/0` | Outbound (NAT GW, AWS API) |

> SSH (port 22) bị comment out. Để truy cập EC2, dùng AWS Systems Manager Session Manager.

### RDS Security Group

| Direction | Port | Protocol | Source | Mục đích |
|-----------|------|----------|--------|----------|
| Ingress | 3306 | TCP | EC2 SG | Nhận MySQL từ App tier |
| Egress | All | All | `0.0.0.0/0` | Outbound (cập nhật, patch) |

---

## Variables

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `project_name` | `string` | Tên project — dùng đặt tên SG |
| `environment` | `string` | Môi trường deploy (`dev`, `prod`) |
| `vpc_id` | `string` | ID của VPC chứa các Security Group |

---

## Outputs

| Tên | Mô tả |
|-----|-------|
| `alb_security_group_id` | SG ID của ALB — input cho module `alb` |
| `app_security_group_id` | SG ID của EC2 — input cho module `ec2`, `autoscaling` |
| `rds_security_group_id` | SG ID của RDS — input cho module `rds` |

---

## Cách sử dụng

```hcl
module "security-group" {
  source = "../../modules/security-group"

  project_name = "three-tier"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id
}
```

---

## Lưu ý thiết kế

- **Tách SG và rule**: SG rỗng được tạo trước, rule được thêm bằng `aws_security_group_rule` để tránh circular dependency giữa ALB SG và EC2 SG.
- **Source Security Group**: EC2 chỉ nhận traffic từ ALB SG (không phải CIDR), RDS chỉ nhận từ EC2 SG — đây là best practice thay vì dùng CIDR.
- **SSH disabled**: Không mở SSH ra internet. Dùng AWS SSM Session Manager để truy cập instance.
- **OPA check**: `networking.rego` sẽ deny nếu Security Group của DB tier có egress `protocol=-1` ra `0.0.0.0/0`.
