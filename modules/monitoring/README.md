# Module: Monitoring

Module tạo hệ thống giám sát toàn diện cho kiến trúc ba tầng, bao gồm CloudWatch Alarms, SNS notifications, CloudWatch Log Groups và CloudWatch Dashboard.

---

## Tài nguyên được tạo

| Resource | Số lượng | Mô tả |
|----------|----------|-------|
| `aws_sns_topic` | 1 | Topic nhận và phân phát cảnh báo |
| `aws_sns_topic_subscription` | 0 hoặc 1 | Email subscription (nếu có `sns_email`) |
| `aws_cloudwatch_metric_alarm` | 8 | Alarm cho App tier, Data tier và Web tier |
| `aws_cloudwatch_log_group` | 2 | Log group cho Web tier và App tier |
| `aws_cloudwatch_dashboard` | 1 | Dashboard tổng hợp 5 biểu đồ |

---

## CloudWatch Alarms

### App Tier — Auto Scaling Group

| Alarm | Điều kiện | Hành động |
|-------|-----------|-----------|
| `asg-cpu-high` | CPU > `asg_cpu_high_threshold`% trong 2 chu kỳ 5 phút | SNS alert |
| `asg-cpu-low` | CPU < `asg_cpu_low_threshold`% trong 2 chu kỳ 5 phút | SNS alert |

### Data Tier — RDS

| Alarm | Điều kiện | Hành động |
|-------|-----------|-----------|
| `rds-cpu-high` | CPU > `rds_cpu_high_threshold`% trong 2 chu kỳ 5 phút | SNS alert |
| `rds-free-storage-low` | FreeStorage < `rds_free_storage_threshold` bytes | SNS alert |
| `rds-connections-high` | Connections > `rds_connections_threshold` trong 2 chu kỳ | SNS alert |

### Web Tier — ALB

| Alarm | Điều kiện | Hành động |
|-------|-----------|-----------|
| `alb-5xx-high` | HTTP 5xx > `alb_5xx_threshold` trong 1 phút × 2 chu kỳ | SNS alert |
| `alb-response-time-high` | Response time > `alb_response_time_threshold`s trong 1 phút × 3 chu kỳ | SNS alert |
| `alb-unhealthy-hosts` | UnhealthyHostCount > 0 trong 1 phút × 2 chu kỳ | SNS alert |

---

## CloudWatch Log Groups

| Log Group | Retention | Mô tả |
|-----------|-----------|-------|
| `/aws/ec2/{env}/app` | `log_retention_days` ngày | Log của EC2 App tier |
| `/aws/ec2/{env}/web` | `log_retention_days` ngày | Log của Web tier |

---

## CloudWatch Dashboard

Dashboard tự động tạo với 5 biểu đồ dạng time-series:

```
┌─────────────────────────┬──────────────────────────┐
│  ASG CPU Utilization    │  RDS CPU Utilization     │
│  (App Tier)             │  (Data Tier)             │
├─────────────────────────┼──────────────────────────┤
│  RDS Free Storage       │  RDS DB Connections      │
│                         │                          │
├─────────────────────────┼──────────────────────────┤
│  ALB 5XX Error Count    │  ALB Target Response Time│
│  (Web Tier)             │  (Web Tier)              │
└─────────────────────────┴──────────────────────────┘
```

URL truy cập dashboard được xuất ra qua output `dashboard_url`.

---

## Variables

### Chung

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `project_name` | `string` | Tên project |
| `environment` | `string` | Môi trường deploy |
| `aws_region` | `string` | AWS Region — dùng trong Dashboard |

### SNS

| Tên | Kiểu | Mặc định | Mô tả |
|-----|------|----------|-------|
| `sns_email` | `string` | `""` | Email nhận cảnh báo. Để trống nếu không muốn |

### App Tier

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `autoscaling_group_name` | `string` | Tên ASG — output từ module `autoscaling` |
| `asg_cpu_high_threshold` | `number` | Ngưỡng CPU cao (%) — ví dụ: `80` |
| `asg_cpu_low_threshold` | `number` | Ngưỡng CPU thấp (%) — ví dụ: `20` |

### Data Tier

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `rds_instance_id` | `string` | RDS instance ID — output từ module `rds` |
| `rds_cpu_high_threshold` | `number` | Ngưỡng CPU RDS (%) — ví dụ: `80` |
| `rds_free_storage_threshold` | `number` | Ngưỡng dung lượng trống (bytes) — ví dụ: `5368709120` (5 GB) |
| `rds_connections_threshold` | `number` | Ngưỡng số kết nối đồng thời — ví dụ: `100` |

### Web Tier

| Tên | Kiểu | Mặc định | Mô tả |
|-----|------|----------|-------|
| `alb_arn_suffix` | `string` | — | ARN suffix ALB — output từ module `alb` |
| `target_group_arn_suffix` | `string` | — | ARN suffix Target Group — output từ module `alb` |
| `alb_5xx_threshold` | `number` | `10` | Số lỗi 5xx/phút trước khi alarm |
| `alb_response_time_threshold` | `number` | — | Response time tối đa (giây) — ví dụ: `2` |

### Log Groups

| Tên | Kiểu | Mô tả |
|-----|------|-------|
| `log_retention_days` | `number` | Số ngày giữ log. Giá trị hợp lệ: 1, 3, 5, 7, 14, 30, 60, 90... |

---

## Outputs

| Tên | Mô tả |
|-----|-------|
| `sns_topic_arn` | ARN SNS topic |
| `sns_topic_name` | Tên SNS topic |
| `asg_cpu_high_alarm_name` | Tên alarm ASG CPU cao |
| `asg_cpu_low_alarm_name` | Tên alarm ASG CPU thấp |
| `rds_cpu_alarm_name` | Tên alarm RDS CPU |
| `rds_free_storage_alarm_name` | Tên alarm RDS storage |
| `rds_connections_alarm_name` | Tên alarm RDS connections |
| `alb_5xx_alarm_name` | Tên alarm ALB 5xx |
| `alb_response_time_alarm_name` | Tên alarm ALB response time |
| `alb_unhealthy_hosts_alarm_name` | Tên alarm ALB unhealthy hosts |
| `app_log_group_name` | Tên Log Group App tier |
| `web_log_group_name` | Tên Log Group Web tier |
| `dashboard_name` | Tên CloudWatch Dashboard |
| `dashboard_url` | URL console để xem Dashboard |

---

## Cách sử dụng

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project_name = "three-tier"
  environment  = "dev"
  aws_region   = "ap-southeast-1"

  sns_email = "alert@example.com"

  autoscaling_group_name = module.autoscaling.autoscaling_group_name
  asg_cpu_high_threshold = 80
  asg_cpu_low_threshold  = 20

  rds_instance_id            = module.rds.rds_instance_id
  rds_cpu_high_threshold     = 80
  rds_free_storage_threshold = 5368709120  # 5 GB in bytes
  rds_connections_threshold  = 100

  alb_arn_suffix              = module.alb.alb_arn_suffix
  target_group_arn_suffix     = module.alb.target_group_arn_suffix
  alb_5xx_threshold           = 10
  alb_response_time_threshold = 2

  log_retention_days = 14
}
```

---

## Lưu ý

- **SNS Email xác nhận**: Sau khi deploy, AWS sẽ gửi email xác nhận đến `sns_email`. Phải click "Confirm subscription" thì mới nhận được cảnh báo.
- **rds_free_storage_threshold**: Đơn vị là **bytes**, không phải GB. `5 GB = 5 * 1024^3 = 5368709120`.
- **Dashboard URL**: Truy cập output `dashboard_url` để mở Dashboard trực tiếp trên AWS Console.
- **OPA compliance**: `compliance.rego` sẽ warn nếu không có `aws_cloudwatch_metric_alarm` cho unauthorized API calls — cân nhắc thêm alarm cho CIS 4.1.
