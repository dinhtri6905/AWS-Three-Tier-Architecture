package terraform

# ==============================================================
# SECURITY POLICIES - AWS Three-Tier Architecture
# Evaluated against: terraform plan JSON (terraform show -json)
# Usage: opa eval -d policies/ -I "data.terraform.deny" < tfplan.json
# ==============================================================

# =======================================================
# SEC-001: Security groups must not allow SSH from 0.0.0.0/0
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.from_port <= 22
    rule.to_port >= 22
    rule.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "[SEC-001] Security group '%s' must not allow SSH (port 22) from 0.0.0.0/0. Use Systems Manager Session Manager instead.",
        [resource.address]
    )
}

# =======================================================
# SEC-002: Security group rules must not allow SSH from 0.0.0.0/0
# (covers aws_security_group_rule resource type)
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.from_port <= 22
    resource.change.after.to_port >= 22
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "[SEC-002] Security group rule '%s' must not allow SSH (port 22) from 0.0.0.0/0.",
        [resource.address]
    )
}

# =======================================================
# SEC-003: Security groups must not allow RDP from 0.0.0.0/0
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.from_port <= 3389
    rule.to_port >= 3389
    rule.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "[SEC-003] Security group '%s' must not allow RDP (port 3389) from 0.0.0.0/0.",
        [resource.address]
    )
}

# =======================================================
# SEC-004: Security groups must not allow all traffic (-1) from 0.0.0.0/0
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.protocol == "-1"
    rule.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "[SEC-004] Security group '%s' must not allow all traffic (protocol -1) from 0.0.0.0/0.",
        [resource.address]
    )
}

# =======================================================
# SEC-005: RDS instances must have storage encryption enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted != true
    msg := sprintf(
        "[SEC-005] RDS instance '%s' must have storage encryption enabled (storage_encrypted = true).",
        [resource.address]
    )
}

# =======================================================
# SEC-006: RDS instances must not be publicly accessible
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.publicly_accessible == true
    msg := sprintf(
        "[SEC-006] RDS instance '%s' must not be publicly accessible. Place in private subnet only.",
        [resource.address]
    )
}

# =======================================================
# SEC-007: RDS instances must have deletion protection enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.deletion_protection != true
    msg := sprintf(
        "[SEC-007] RDS instance '%s' must have deletion_protection = true.",
        [resource.address]
    )
}

# =======================================================
# SEC-008: RDS backup retention period must be at least 7 days
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.backup_retention_period < 7
    msg := sprintf(
        "[SEC-008] RDS instance '%s' backup_retention_period is %d days. Minimum required is 7 days.",
        [resource.address, resource.change.after.backup_retention_period]
    )
}

# =======================================================
# SEC-009: EC2 instances must enforce IMDSv2
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    metadata := resource.change.after.metadata_options[_]
    metadata.http_tokens != "required"
    msg := sprintf(
        "[SEC-009] EC2 instance '%s' must enforce IMDSv2 (metadata_options.http_tokens = 'required').",
        [resource.address]
    )
}

# Warn if no metadata_options is defined (defaults to IMDSv1)
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.metadata_options
    msg := sprintf(
        "[SEC-009W] EC2 instance '%s' has no metadata_options configured. IMDSv1 may be enabled by default.",
        [resource.address]
    )
}

# =======================================================
# SEC-010: Launch templates must enforce IMDSv2
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_launch_template"
    metadata := resource.change.after.metadata_options[_]
    metadata.http_tokens != "required"
    msg := sprintf(
        "[SEC-010] Launch template '%s' must enforce IMDSv2 (metadata_options.http_tokens = 'required').",
        [resource.address]
    )
}

# =======================================================
# SEC-011: EBS volumes must have encryption enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_ebs_volume"
    resource.change.after.encrypted != true
    msg := sprintf(
        "[SEC-011] EBS volume '%s' must have encryption enabled.",
        [resource.address]
    )
}

# =======================================================
# SEC-012: S3 buckets must block all public access
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    after := resource.change.after
    after.block_public_acls != true
    msg := sprintf(
        "[SEC-012] S3 public access block '%s' must set block_public_acls = true.",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    after := resource.change.after
    after.block_public_policy != true
    msg := sprintf(
        "[SEC-012] S3 public access block '%s' must set block_public_policy = true.",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    after := resource.change.after
    after.ignore_public_acls != true
    msg := sprintf(
        "[SEC-012] S3 public access block '%s' must set ignore_public_acls = true.",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    after := resource.change.after
    after.restrict_public_buckets != true
    msg := sprintf(
        "[SEC-012] S3 public access block '%s' must set restrict_public_buckets = true.",
        [resource.address]
    )
}

# =======================================================
# SEC-013: S3 buckets must have server-side encryption enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.server_side_encryption_configuration
    msg := sprintf(
        "[SEC-013] S3 bucket '%s' must have server-side encryption enabled.",
        [resource.address]
    )
}

# =======================================================
# SEC-014: ALB listeners on port 80 must redirect to HTTPS
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb_listener"
    resource.change.after.port == 80
    action := resource.change.after.default_action[_]
    action.type != "redirect"
    msg := sprintf(
        "[SEC-014] ALB listener '%s' on port 80 must use a redirect action to HTTPS, not serve traffic directly.",
        [resource.address]
    )
}

# =======================================================
# SEC-015: IAM policies must not allow wildcard action on wildcard resource
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action == "*"
    statement.Resource == "*"
    msg := sprintf(
        "[SEC-015] IAM policy '%s' must not allow wildcard action (*) on wildcard resource (*). Apply least privilege.",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action[_] == "*"
    statement.Resource[_] == "*"
    msg := sprintf(
        "[SEC-015] IAM policy '%s' must not allow wildcard action (*) on wildcard resource (*). Apply least privilege.",
        [resource.address]
    )
}

# =======================================================
# SEC-016: ALB must have deletion protection enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    resource.change.after.enable_deletion_protection != true
    msg := sprintf(
        "[SEC-016] ALB '%s' must have enable_deletion_protection = true.",
        [resource.address]
    )
}

# =======================================================
# SEC-017: ALB must have access logging enabled
# =======================================================
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    not resource.change.after.access_logs
    msg := sprintf(
        "[SEC-017W] ALB '%s' should have access logging enabled for audit and troubleshooting.",
        [resource.address]
    )
}
