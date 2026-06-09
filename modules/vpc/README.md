# Module: VPC

Module Terraform tạo toàn bộ hạ tầng mạng cho kiến trúc ba tầng trên AWS, bao gồm VPC, subnet theo từng tier, Internet Gateway, NAT Gateway trên từng AZ và Route Table tương ứng.

---

## Tài nguyên được tạo

| Resource | Số lượng | Mô tả |
|----------|----------|-------|
| `aws_vpc` | 1 | VPC chính, bật DNS support và DNS hostnames |
| `aws_internet_gateway` | 1 | Internet Gateway gắn vào VPC |
| `aws_subnet` (public) | N (theo AZ) | Subnet public cho ALB và NAT Gateway |
| `aws_subnet` (app) | N (theo AZ) | Subnet private cho EC2 Application servers |
| `aws_subnet` (db) | N (theo AZ) | Subnet private cho RDS Database |
| `aws_eip` | N (theo AZ) | Elastic IP cho mỗi NAT Gateway |
| `aws_nat_gateway` | N (theo AZ) | NAT Gateway mỗi AZ — High Availability |
| `aws_route_table` (public) | 1 | Route `0.0.0.0/0` → Internet Gateway |
| `aws_route_table` (app) | N (theo AZ) | Route `0.0.0.0/0` → NAT Gateway tương ứng |
| `aws_route_table` (db) | 1 | Không có route ra internet |

---

## Thiết kế mạng

```
Internet
    │
    ▼
┌────────────────────────────────────────┐  Public Subnets
│  10.0.1.0/24  10.0.2.0/24  10.0.3.0/24│  ap-southeast-1a/b/c
│  ALB · NAT-GW-1 · NAT-GW-2 · NAT-GW-3 │
└────────────────────────────────────────┘
    │ NAT (outbound only)
    ▼
┌────────────────────────────────────────┐  Private App Subnets
│  10.0.11.0/24 · 10.0.12.0/24 · 10.0.13.0/24 │
│  EC2 Application Servers · ASG         │
└────────────────────────────────────────┘
    │ App port only
    ▼
┌────────────────────────────────────────┐  Private DB Subnets
│  10.0.21.0/24 · 10.0.22.0/24 · 10.0.23.0/24 │
│  RDS MySQL (no internet route)         │
└────────────────────────────────────────┘
```

**Phân tách traffic:**
- **Public Subnet**: map_public_ip_on_launch = true — dành cho ALB và NAT Gateway
- **App Subnet**: Tier tag = `Application`, không có public IP, ra internet qua NAT Gateway theo AZ
- **DB Subnet**: Tier tag = `Database`, hoàn toàn cô lập, không có route ra internet

---

## Variables

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `project_name` | `string` | Tên project — dùng để đặt tên resource |
| `environment` | `string` | Môi trường deploy (`dev`, `prod`) |
| `vpc_cidr` | `string` | CIDR block của VPC (ví dụ: `10.0.0.0/16`) |
| `availability_zones` | `list(string)` | Danh sách AZ — quyết định số subnet và NAT GW tạo ra |
| `public_subnet_cidrs` | `list(string)` | CIDR cho các Public Subnet, phải khớp số AZ |
| `app_subnet_cidrs` | `list(string)` | CIDR cho các App Subnet, phải khớp số AZ |
| `db_subnet_cidrs` | `list(string)` | CIDR cho các DB Subnet, phải khớp số AZ |

---

## Outputs

| Tên | Mô tả |
|-----|-------|
| `vpc_id` | ID của VPC — dùng làm input cho các module khác |
| `internet_gateway_id` | ID Internet Gateway |
| `public_subnet_ids` | List ID các Public Subnet — input cho module `alb` |
| `app_subnet_ids` | List ID các App Subnet — input cho module `ec2`, `autoscaling` |
| `db_subnet_ids` | List ID các DB Subnet — input cho module `rds` |
| `nat_gateway_ids` | List ID các NAT Gateway |
| `public_route_table_id` | ID Route Table public |
| `app_route_table_ids` | List ID Route Table của App tier |
| `db_route_table_id` | ID Route Table của DB tier |

---

## Cách sử dụng

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name = "three-tier"
  environment  = "dev"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]

  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  app_subnet_cidrs    = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  db_subnet_cidrs     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}
```

---

## Lưu ý

- **NAT Gateway per AZ**: Module tạo một NAT Gateway trên mỗi AZ để đảm bảo High Availability. Chi phí sẽ cao hơn nhưng tránh single point of failure.
- **checkov skip**: `CKV2_AWS_11` (VPC Flow Logs) và `CKV2_AWS_12` (Default SG) bị skip cho môi trường lab — production nên bật VPC Flow Logs.
- Số lượng subnet và NAT Gateway phụ thuộc vào `length(var.availability_zones)`, không cần thay đổi code khi thêm AZ.
