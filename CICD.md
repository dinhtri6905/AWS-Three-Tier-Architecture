```bash
Workflow Files
terraform-ci.yml - CI checks for dev (validate, tflint, tfsec, checkov) - triggered on push/PR to develop and feature/**
terraform-cd.yml - CD deployment for dev (plan, opa-gate, deploy, destroy)
check-scan.yml - Periodic security scan (OPA full check, tfsec deep, reports)
policies/security.rego - Security policies
policies/networking.rego - Networking policies
policies/compliance.rego - CIS Benchmark compliance

OPA/Rego Policy Files
security.rego:

    IAM policies - no full permissions (CIS 5.2)
    Security groups - no open ingress on all ports
    RDS - encryption at rest
    EC2 - no public IPs on instances in private subnets
    Secrets not hardcoded

networking.rego:

    VPC flow logs enabled
    Subnets don't auto-assign public IPs (for private subnets)
    Security groups don't have overly permissive rules
    NAT gateway requirements

compliance.rego:

    CIS Benchmark checks
    S3 bucket encryption
    S3 versioning
    CloudTrail enabled
    CloudWatch monitoring
    Tagging requirements
```