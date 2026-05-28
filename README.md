# AWS-Three-Tier-Architecture

## Thành phần:
- Presentation Tier (Web Layer)
    + Public Subnet
    + Application Load Balancer (ALB)
    + EC2 Web Servers
- Application Tier
    + Private Subnet
    + EC2 Application Servers
    + Auto Scaling Group
- Data Tier
    + Private Subnet
    + Database (MySQL/PostgreSQL trên RDS)
- Thành phần bổ sung:
    + VPC
    + Internet Gateway
    + NAT Gateway
    + Route Tables
    + Security Groups
    + IAM
    + CloudWatch

### Kiến trúc cuối:
```bash
Internet
    ↓
Application Load Balancer
    ↓
Web Tier (EC2 Public)
    ↓
App Tier (EC2 Private)
    ↓
Database Tier (RDS Private)
```
---

### Integrated GitHub Actions CI/CD pipeline with:
- TFLint for Terraform linting
- tfsec for infrastructure security scanning
- Checkov for CIS compliance validation
- OPA/Rego for policy-as-code enforcement

| Tool     | Vai trò trong CI/CD                                                                    |
| -------- | -------------------------------------------------------------------------------------- |
| TFLint   | Kiểm tra Terraform syntax, AWS best practice, phát hiện cấu hình sai                   |
| tfsec    | Quét lỗi bảo mật cho Infrastructure as Code                                            |
| Checkov  | Quét security và compliance, hỗ trợ nhiều framework như AWS Foundations, NIST, PCI DSS |
| OPA/Rego | Policy as Code, tự định nghĩa quy tắc và chính sách tổ chức                            |

```bash
Developer Push/Pull Request
            ↓
GitHub Actions
            ↓
Terraform Format (fmt)
            ↓
Terraform Validate
            ↓
TFLint
            ↓
tfsec
            ↓
Checkov
            ↓
OPA/Rego Policy Check
            ↓
Terraform Plan
            ↓
Manual Approval
            ↓
Terraform Apply
            ↓
Deploy AWS Infrastructure
```

```bash
AWS-Three-Tier-Architecture/
│
├── backend/
│   ├── backend.tf
│   └── terraform.tfvars
│
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   ├── outputs.tf
│   │   └── backend.tf
│   │
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│       └── backend.tf
│
├── modules/
│   ├── vpc/
│   ├── security-group/
│   ├── alb/
│   ├── ec2/
│   ├── autoscaling/
│   ├── rds/
│   ├── iam/
│   ├── monitoring/
│   └── bastion/
│
├── scripts/
│   ├── user-data.sh
│   └── install-nginx.sh
│
├── diagrams/
│   └── architecture.png
│
├── .github/
│   └── workflows/
│       ├── terraform-ci.yml
│       └── terraform-cd.yml
│
├── providers.tf
├── versions.tf
├── outputs.tf
├── README.md
└── .gitignore
```