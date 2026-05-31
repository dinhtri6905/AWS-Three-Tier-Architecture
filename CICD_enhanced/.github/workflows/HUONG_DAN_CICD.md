# Huong dan trien khai CI/CD tu Dev den Prod
# AWS Three-Tier Architecture

---

## Tong quan

Pipeline co 2 luong chinh:
- Dev flow: code -> PR -> CI checks -> merge -> tu dong deploy dev
- Prod flow: thu cong chay workflow -> phe duyet -> deploy prod

Secrets can setup: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, BUCKET_TF_STATE, SLACK_WEBHOOK_URL
GitHub Environments can tao: development, production (co required reviewers)

---

## BUOC 1: Chuan bi AWS

### 1.1 Tao S3 bucket luu Terraform state

```bash
# Tao bucket (doi ten bucket cho phu hop)
aws s3api create-bucket \
  --bucket your-project-terraform-state \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

# Bat versioning (quan trong - de rollback khi can)
aws s3api put-bucket-versioning \
  --bucket your-project-terraform-state \
  --versioning-configuration Status=Enabled

# Bat encryption
aws s3api put-bucket-encryption \
  --bucket your-project-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Chan public access
aws s3api put-public-access-block \
  --bucket your-project-terraform-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### 1.2 Tao DynamoDB table cho state locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

### 1.3 Tao IAM User cho GitHub Actions

```bash
# Tao user
aws iam create-user --user-name github-actions-cicd

# Tao policy file
cat > github-actions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-project-terraform-state",
        "arn:aws:s3:::your-project-terraform-state/*"
      ]
    },
    {
      "Sid": "TerraformStateLock",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-southeast-1:*:table/terraform-state-lock"
    },
    {
      "Sid": "EC2Access",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "autoscaling:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSAccess",
      "Effect": "Allow",
      "Action": [
        "rds:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "VPCAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:DescribeNatGateways",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DescribeSecurityGroups",
        "ec2:CreateFlowLogs",
        "ec2:DeleteFlowLogs",
        "ec2:DescribeFlowLogs"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMAccess",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:PassRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:GetInstanceProfile"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchAccess",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*",
        "logs:*",
        "cloudtrail:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSAccess",
      "Effect": "Allow",
      "Action": [
        "kms:CreateKey",
        "kms:DeleteKey",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:ListAliases",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:TagResource"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Tao va attach policy
aws iam create-policy \
  --policy-name GitHubActionsTerraformPolicy \
  --policy-document file://github-actions-policy.json

aws iam attach-user-policy \
  --user-name github-actions-cicd \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActionsTerraformPolicy

# Tao access key (luu ket qua nay - chi hien thi 1 lan)
aws iam create-access-key --user-name github-actions-cicd
```

Luu lai AccessKeyId va SecretAccessKey tu output o tren.

### 1.4 Cap nhat backend.tf cho moi environment

Sua file environments/dev/backend.tf:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-project-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

Sua file environments/prod/backend.tf:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-project-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

---

## BUOC 2: Chuan bi GitHub

### 2.1 Them Secrets vao repository

Vao GitHub -> Repository -> Settings -> Secrets and variables -> Actions -> New repository secret

Them lan luot cac secret sau:

```
Secret name                  | Gia tri
-----------------------------|------------------------------------------
AWS_ACCESS_KEY_ID            | AccessKeyId tu buoc 1.3
AWS_SECRET_ACCESS_KEY        | SecretAccessKey tu buoc 1.3
AWS_ACCESS_KEY_ID_PROD       | (co the dung chung hoac tao user rieng cho prod)
AWS_SECRET_ACCESS_KEY_PROD   | (tuong tu)
BUCKET_TF_STATE              | your-project-terraform-state
SLACK_WEBHOOK_URL            | URL webhook tu Slack (xem phan 2.2)
```

### 2.2 Lay Slack Webhook URL (neu can thong bao)

1. Vao https://api.slack.com/apps
2. Create New App -> From scratch
3. Dat ten app: "Terraform Deploy Bot", chon workspace
4. Chon "Incoming Webhooks" -> Activate
5. Add New Webhook to Workspace -> chon channel
6. Copy Webhook URL -> them vao GitHub Secret SLACK_WEBHOOK_URL

Neu khong dung Slack, comment dong notify-slack trong terraform-deploy.yaml.

### 2.3 Tao GitHub Environments

Vao GitHub -> Repository -> Settings -> Environments

Tao environment "development":
- Click "New environment"
- Name: development
- Khong can them gi them (tu dong deploy)

Tao environment "production":
- Click "New environment"
- Name: production
- Tich vao "Required reviewers"
- Add reviewers: them ten GitHub account cua ban hoac toan bo team
- Click Save protection rules

Day la gate quan trong nhat: khi deploy prod chay, GitHub se gui notification cho reviewer va cho phep/tu choi truoc khi apply.

---

## BUOC 3: Tao cac file config con thieu

### 3.1 Tao file .tflint.hcl (root cua project)

```hcl
config {
  format              = "compact"
  plugin_dir          = "~/.tflint.d/plugins"
  module              = false
  disabled_by_default = false
}

plugin "aws" {
  enabled = true
  version = "0.35.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  enabled = true
  version = "0.9.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset  = "recommended"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  variable { format = "snake_case" }
  resource { format = "snake_case" }
  output   { format = "snake_case" }
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_db_instance_invalid_type" {
  enabled = true
}

rule "aws_db_instance_default_parameter_group" {
  enabled = true
}
```

### 3.2 Tao file .checkov.yaml (root cua project)

```yaml
directory:
  - "."

framework:
  - terraform

download-external-modules: false
evaluate-variables: true

check:
  - CKV_AWS_7
  - CKV_AWS_16
  - CKV_AWS_17
  - CKV_AWS_19
  - CKV_AWS_20
  - CKV_AWS_21
  - CKV_AWS_23
  - CKV_AWS_24
  - CKV_AWS_25
  - CKV_AWS_35
  - CKV_AWS_36
  - CKV_AWS_67
  - CKV_AWS_86
  - CKV_AWS_91
  - CKV_AWS_129
  - CKV_AWS_133
  - CKV_AWS_145
  - CKV_AWS_150
  - CKV_AWS_157
  - CKV_AWS_189
  - CKV_AWS_315
  - CKV2_AWS_5
  - CKV2_AWS_12

skip-check:
  - CKV_AWS_131
  - CKV_AWS_103

output:
  - cli
  - json
  - sarif

compact: true
soft-fail: true
```

### 3.3 Kiem tra cau truc thu muc cuoi cung

```
AWS-Three-Tier-Architecture/
├── .github/
│   └── workflows/
│       ├── terraform-pull-request.yaml   <- da tao
│       └── terraform-deploy.yaml         <- da tao
├── .tflint.hcl                           <- vua tao o buoc 3.1
├── .checkov.yaml                         <- vua tao o buoc 3.2
├── environments/
│   ├── dev/
│   │   ├── backend.tf                    <- da cap nhat o buoc 1.4
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf                    <- can co output alb_dns_name
│   │   ├── providers.tf
│   │   ├── terraform.tfvars
│   │   └── versions.tf
│   └── prod/
│       └── ... (tuong tu dev)
├── modules/
│   ├── vpc/
│   ├── security-group/
│   ├── alb/
│   ├── ec2/
│   ├── autoscaling/
│   ├── rds/
│   └── monitoring/
└── policies/
    ├── security.rego                     <- da tao
    ├── networking.rego                   <- da tao
    └── compliance.rego                   <- da tao
```

Luu y: environments/dev/outputs.tf can co:

```hcl
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}
```

---

## BUOC 4: Push code len GitHub

### 4.1 Commit va push

```bash
# Di chuyen vao thu muc project
cd AWS-Three-Tier-Architecture

# Kiem tra tat ca file da co
ls .github/workflows/
ls policies/
ls .tflint.hcl .checkov.yaml

# Them tat ca vao git
git add .
git commit -m "feat: add CI/CD pipeline with security scanning

- Add terraform-pull-request.yaml: CI checks on PR
- Add terraform-deploy.yaml: CD deployment to dev and prod
- Add OPA/Rego policies: security, networking, CIS compliance
- Add .tflint.hcl: TFLint configuration
- Add .checkov.yaml: Checkov CIS benchmark configuration"

git push origin main
```

### 4.2 Kiem tra GitHub Actions da nhan workflow

1. Vao GitHub -> Repository -> Actions tab
2. Kiem tra tab "All workflows" co hien thi:
   - "CI - Terraform PR Checks"
   - "CD - Terraform Deploy"

Neu khong hien thi: kiem tra lai folder .github/workflows/ da push len chua.

---

## BUOC 5: Test PR Workflow (Dev Flow)

### 5.1 Tao feature branch va tao thay doi nho

```bash
# Tao branch moi
git checkout -b feature/test-cicd-pipeline

# Tao mot thay doi nho de test (vi du them comment vao variables.tf)
echo "# Test CI/CD pipeline" >> environments/dev/variables.tf

# Commit
git add environments/dev/variables.tf
git commit -m "test: add comment to test CI/CD pipeline"

# Push len GitHub
git push origin feature/test-cicd-pipeline
```

### 5.2 Mo Pull Request

1. Vao GitHub -> Repository -> Pull requests -> New pull request
2. base: main <- compare: feature/test-cicd-pipeline
3. Them title: "test: verify CI/CD pipeline"
4. Click "Create pull request"

### 5.3 Theo doi CI checks

Sau khi tao PR, cac jobs sau se chay tu dong:

```
Validate Terraform      -> kiem tra fmt va validate
TFLint Analysis         -> lint Terraform files
Checkov Security Scan   -> CIS benchmark scan
tfsec Security Scan     -> IaC security scan
OPA Policy Compliance   -> policy checks
Terraform Plan          -> hien thi plan output
PR Check Summary        -> tong ket ket qua
```

Thoi gian chay: khoang 5-10 phut.

Sau khi xong, scroll xuong PR de xem comments tu tung job.

### 5.4 Xu ly khi co loi

Neu job "Validate Terraform" fail vi format:

```bash
# Sua format tu dong
terraform fmt -recursive

# Commit va push lai
git add .
git commit -m "fix: terraform formatting"
git push origin feature/test-cicd-pipeline
```

Neu job "TFLint Analysis" fail:
- Xem comment o PR de biet loi cu the
- Sua file Terraform theo huong dan

Neu job "Checkov Security Scan" fail:
- Xem danh sach checks bi fail o PR comment
- Co 2 cach xu ly:
  a. Sua Terraform code cho dung (khuyen nghi)
  b. Them check_id vao skip-check trong .checkov.yaml (neu co ly do hop le)

Neu job "OPA Policy Compliance" fail:
- Xem danh sach violations o PR comment (bao gom ma SEC-001, NET-001, CIS-3.1...)
- Sua Terraform code theo violation message

### 5.5 Merge PR

Khi tat ca checks PASSED:
1. PR se hien thi "All checks have passed"
2. Request review tu teammate (neu co)
3. Click "Merge pull request" -> "Confirm merge"

---

## BUOC 6: Deploy Dev (tu dong)

### 6.1 Sau khi merge, workflow tu dong chay

Sau khi merge vao main, terraform-deploy.yaml se tu dong:
1. Chay job "Validate Terraform"
2. Chay job "Security Gate" (Checkov + OPA)
3. Chay job "Deploy dev" voi:
   - terraform init
   - terraform plan
   - terraform apply -auto-approve

### 6.2 Theo doi tien trinh deploy

1. Vao GitHub -> Actions tab
2. Click vao workflow run "CD - Terraform Deploy" dang chay
3. Xem tung job va step

Thoi gian deploy lan dau: 10-20 phut (tuy vao so luong resource).

### 6.3 Kiem tra ket qua tren AWS Console

Sau khi deploy xong, kiem tra tren AWS:

```
AWS Console -> Regions: ap-southeast-1

VPC:
  - Vao VPC Console -> Your VPCs
  - Tim VPC co tag Environment=dev

EC2:
  - Vao EC2 Console -> Instances
  - Kiem tra Web Tier va App Tier instances dang Running

RDS:
  - Vao RDS Console -> Databases
  - Kiem tra database dang Available

Load Balancer:
  - Vao EC2 Console -> Load Balancers
  - Copy DNS name va mo tren browser
```

ALB DNS name cung duoc hien thi trong GitHub Actions summary:
- Vao Actions -> Workflow run -> job "Deploy dev" -> summary

---

## BUOC 7: Deploy Prod (thu cong + phe duyet)

### 7.1 Chay workflow thu cong

1. Vao GitHub -> Actions tab
2. Chon workflow "CD - Terraform Deploy" o sidebar trai
3. Click "Run workflow" (nut xanh ben phai)
4. Dien vao form:
   ```
   Target environment : prod
   Terraform action   : apply
   destroy_confirm    : (de trong)
   ```
5. Click "Run workflow"

### 7.2 Doi reviewer phe duyet

Sau khi click Run workflow:
1. Job "Validate" va "Security Gate" se chay truoc
2. Khi den job "Deploy prod", workflow se dung lai va gui notification
3. Reviewer se nhan email tu GitHub: "Your review is required"

De phe duyet:
1. Reviewer vao link trong email hoac vao Actions -> Workflow run
2. Tim job "Deploy prod" dang cho (hien thi "Waiting")
3. Click "Review deployments"
4. Tick chon "production"
5. Chon "Approve and deploy"

Neu tu choi: chon "Reject" va ghi ro ly do.

### 7.3 Theo doi deploy prod

Sau khi duoc phe duyet:
1. Job "Deploy prod" se chay tiep
2. terraform init -> terraform plan -> terraform apply
3. Ket qua se hien thi trong GitHub Step Summary

### 7.4 Xac nhan prod da deploy thanh cong

Kiem tra Slack channel da nhan thong bao (neu da cau hinh webhook).

Kiem tra AWS Console voi Environment=prod tag.

---

## BUOC 8: Destroy infra (khi khong can nua)

### 8.1 Destroy dev

```
GitHub -> Actions -> CD - Terraform Deploy -> Run workflow

Target environment : dev
Terraform action   : destroy
destroy_confirm    : DESTROY
```

Luu y: phai go chinh xac chu "DESTROY" (chu hoa) o truong destroy_confirm.

### 8.2 Destroy prod

Tuong tu nhu dev nhung chon environment = prod.
Van can reviewer phe duyet truoc khi destroy.

---

## XU LY SU CO THUONG GAP

### Loi: "Error: No valid credential sources found"

```
Nguyen nhan: GitHub Secret chua duoc set hoac sai.
Kiem tra: Settings -> Secrets -> Actions
Dam bao AWS_ACCESS_KEY_ID va AWS_SECRET_ACCESS_KEY da duoc them.
```

### Loi: "Error: S3 bucket does not exist"

```
Nguyen nhan: Bien BUCKET_TF_STATE sai ten bucket.
Kiem tra: Secret BUCKET_TF_STATE phai khop voi ten bucket da tao o buoc 1.1.
```

### Loi: "Error acquiring the state lock"

```
Nguyen nhan: Co mot deploy dang chay truoc do bi loi chua giai phong lock.
Cach sua:
  aws dynamodb delete-item \
    --table-name terraform-state-lock \
    --key '{"LockID": {"S": "your-bucket/dev/terraform.tfstate"}}'
```

### Loi: "OPA found X policy violations"

```
Nguyen nhan: Terraform code vi pham policies trong thu muc policies/.
Cach sua: Doc ro violation message (SEC-001, NET-005, CIS-3.1...) va sua Terraform code.
Xem comment tren PR de biet file va resource nao bi vi pham.
```

### Loi: "Checkov found failed checks"

```
Nguyen nhan: Terraform code khong dap ung CIS benchmark.
Cach 1 (khuyen nghi): Sua Terraform code them encryption, deletion_protection, multi_az...
Cach 2: Them check ID vao skip-check trong .checkov.yaml voi comment giai thich ly do.
```

### CI checks pass nhung deploy van fail

```
Kiem tra:
1. IAM User co du quyen khong? (Xem policy o buoc 1.3)
2. Region co dung khong? (ap-southeast-1)
3. Terraform modules co loi khong? (Xem logs trong Actions tab)
```

### GitHub Environment "production" khong xuat hien

```
Nguyen nhan: Workflow chua chay lan nao nen GitHub chua tao Environment tu dong.
Cach sua: Tao thu cong tai Settings -> Environments -> New environment -> production
```

---

## TOM TAT CHECKLIST

### Truoc khi bat dau

- [ ] Da cai AWS CLI va dang nhap (aws configure)
- [ ] Da tao S3 bucket cho state (buoc 1.1)
- [ ] Da tao DynamoDB table (buoc 1.2)
- [ ] Da tao IAM User va lay access key (buoc 1.3)
- [ ] Da cap nhat backend.tf cho dev va prod (buoc 1.4)
- [ ] Da them 4 GitHub Secrets (buoc 2.1)
- [ ] Da tao 2 GitHub Environments (buoc 2.3)
- [ ] Da tao .tflint.hcl (buoc 3.1)
- [ ] Da tao .checkov.yaml (buoc 3.2)
- [ ] outputs.tf co output alb_dns_name (buoc 3.3)

### Khi tao PR

- [ ] Mo PR tu feature branch vao main
- [ ] Doi tat ca 7 CI checks chay xong
- [ ] Xu ly het cac loi (FAILED jobs)
- [ ] Merge khi tat ca PASSED

### Khi deploy dev

- [ ] Merge vao main trigger tu dong
- [ ] Theo doi 3 jobs: validate -> security-gate -> deploy-dev
- [ ] Xac nhan resources tren AWS Console

### Khi deploy prod

- [ ] Chay workflow thu cong tu Actions tab
- [ ] Chon environment=prod, action=apply
- [ ] Reviewer phe duyet qua email notification
- [ ] Theo doi deploy-prod job
- [ ] Xac nhan Slack notification thanh cong
