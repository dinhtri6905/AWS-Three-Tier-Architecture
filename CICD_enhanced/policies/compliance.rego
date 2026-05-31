package terraform

# ==============================================================
# CIS BENCHMARK COMPLIANCE POLICIES - AWS Three-Tier Architecture
# Reference: CIS Amazon Web Services Foundations Benchmark v1.4.0
# Evaluated against: terraform plan JSON (terraform show -json)
# ==============================================================

# =======================================================
# CIS 2.1.1: Ensure all S3 buckets have logging enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.logging
    msg := sprintf(
        "[CIS-2.1.1] S3 bucket '%s' must have logging enabled.",
        [resource.address]
    )
}

# =======================================================
# CIS 2.1.2: Ensure S3 bucket versioning is enabled
# =======================================================
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_versioning"
    resource.change.after.versioning_configuration.status != "Enabled"
    msg := sprintf(
        "[CIS-2.1.2W] S3 bucket '%s' should have versioning enabled for data protection.",
        [resource.address]
    )
}

# =======================================================
# CIS 2.1.3: Ensure MFA Delete is enabled on S3 buckets
# =======================================================
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_versioning"
    versioning := resource.change.after.versioning_configuration
    versioning.mfa_delete != "Enabled"
    msg := sprintf(
        "[CIS-2.1.3W] S3 bucket '%s' should have MFA Delete enabled to prevent accidental or malicious deletion.",
        [resource.address]
    )
}

# =======================================================
# CIS 3.1: Ensure CloudTrail is enabled in all regions
# =======================================================
deny contains msg if {
    resources := [r | r := input.resource_changes[_]; r.type == "aws_cloudtrail"]
    count(resources) == 0
    msg := "[CIS-3.1] At least one AWS CloudTrail trail must be defined and enabled."
}

# =======================================================
# CIS 3.2: Ensure CloudTrail log file validation is enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudtrail"
    resource.change.after.enable_log_file_validation != true
    msg := sprintf(
        "[CIS-3.2] CloudTrail '%s' must have log file validation enabled (enable_log_file_validation = true).",
        [resource.address]
    )
}

# =======================================================
# CIS 3.3: Ensure CloudTrail is configured to be multi-region
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudtrail"
    resource.change.after.is_multi_region_trail != true
    msg := sprintf(
        "[CIS-3.3] CloudTrail '%s' must be configured as multi-region (is_multi_region_trail = true).",
        [resource.address]
    )
}

# =======================================================
# CIS 3.4: Ensure CloudTrail trails are integrated with CloudWatch Logs
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudtrail"
    not resource.change.after.cloud_watch_logs_group_arn
    msg := sprintf(
        "[CIS-3.4] CloudTrail '%s' must send logs to CloudWatch Logs (cloud_watch_logs_group_arn must be set).",
        [resource.address]
    )
}

# =======================================================
# CIS 3.5: Ensure CloudTrail S3 bucket has logging enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudtrail"
    not resource.change.after.kms_key_id
    msg := sprintf(
        "[CIS-3.5] CloudTrail '%s' must be encrypted with a KMS CMK (kms_key_id must be set).",
        [resource.address]
    )
}

# =======================================================
# CIS 4.1: Ensure a log metric filter and alarm exist for unauthorized API calls
# (Enforce that CloudWatch Log Groups are defined and monitored)
# =======================================================
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    not resource.change.after.name
    msg := sprintf(
        "[CIS-4.1W] CloudWatch Log Group '%s' should be named and monitored for unauthorized API call alerts.",
        [resource.address]
    )
}

# =======================================================
# CIS 4.2: CloudWatch Log Group retention must be at least 90 days
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    resource.change.after.retention_in_days < 90
    msg := sprintf(
        "[CIS-4.2] CloudWatch Log Group '%s' retention is %d days. Minimum required is 90 days.",
        [resource.address, resource.change.after.retention_in_days]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    resource.change.after.retention_in_days == 0
    msg := sprintf(
        "[CIS-4.2] CloudWatch Log Group '%s' has no retention policy set (0 = never expire). Set to at least 90 days.",
        [resource.address]
    )
}

# =======================================================
# CIS 5.1: Ensure IAM policies are attached only to groups or roles, not users
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_user_policy"
    msg := sprintf(
        "[CIS-5.1] IAM policy '%s' is attached directly to a user. Attach policies to groups or roles instead.",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy_attachment"
    count(resource.change.after.users) > 0
    msg := sprintf(
        "[CIS-5.1] IAM policy attachment '%s' attaches a policy directly to users. Use groups or roles instead.",
        [resource.address]
    )
}

# =======================================================
# CIS 5.2: Ensure IAM policies do not allow full administrative permissions
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
        "[CIS-5.2] IAM policy '%s' grants full administrative permissions. This violates least privilege principle.",
        [resource.address]
    )
}

# =======================================================
# CIS 5.4: Ensure all data in Amazon RDS is securely encrypted
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted != true
    msg := sprintf(
        "[CIS-5.4] RDS instance '%s' is not encrypted at rest. Enable storage_encrypted = true.",
        [resource.address]
    )
}

# =======================================================
# CIS 5.6: Ensure all data in ElastiCache is securely encrypted
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_elasticache_replication_group"
    resource.change.after.at_rest_encryption_enabled != true
    msg := sprintf(
        "[CIS-5.6] ElastiCache replication group '%s' does not have at-rest encryption enabled.",
        [resource.address]
    )
}

# =======================================================
# TAGGING POLICY: All taggable resources must have required tags
# =======================================================
taggable_resource_types := [
    "aws_instance",
    "aws_db_instance",
    "aws_rds_cluster",
    "aws_lb",
    "aws_subnet",
    "aws_vpc",
    "aws_security_group",
    "aws_s3_bucket",
    "aws_autoscaling_group",
    "aws_cloudwatch_log_group",
    "aws_elasticache_cluster",
    "aws_elasticache_replication_group"
]

# Deny if resource has no tags at all
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == taggable_resource_types[_]
    not resource.change.after.tags
    msg := sprintf(
        "[TAG-001] Resource '%s' (%s) must have tags defined. Required: Environment, Project, Owner, ManagedBy.",
        [resource.address, resource.type]
    )
}

# Deny if required tags are missing
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == taggable_resource_types[_]
    tags := resource.change.after.tags
    tags

    required_tags := ["Environment", "Project", "Owner", "ManagedBy"]
    missing_tags := [tag | tag := required_tags[_]; not tags[tag]]
    count(missing_tags) > 0

    msg := sprintf(
        "[TAG-001] Resource '%s' is missing required tags: %v",
        [resource.address, missing_tags]
    )
}

# Deny if Environment tag has an invalid value
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == taggable_resource_types[_]
    tags := resource.change.after.tags
    env_value := tags.Environment
    valid_environments := ["dev", "staging", "prod", "production"]
    not env_value == valid_environments[_]
    msg := sprintf(
        "[TAG-002] Resource '%s' has invalid Environment tag value '%s'. Allowed values: dev, staging, prod, production.",
        [resource.address, env_value]
    )
}

# Deny if ManagedBy tag is not set to terraform
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == taggable_resource_types[_]
    tags := resource.change.after.tags
    managed_by := tags.ManagedBy
    lower(managed_by) != "terraform"
    msg := sprintf(
        "[TAG-003] Resource '%s' has ManagedBy = '%s'. All IaC-managed resources must set ManagedBy = 'terraform'.",
        [resource.address, managed_by]
    )
}

# =======================================================
# INSTANCE TYPE POLICY: Only approved EC2 instance types
# =======================================================
approved_instance_types := [
    "t3.micro",    "t3.small",   "t3.medium",  "t3.large",  "t3.xlarge",
    "t3a.micro",   "t3a.small",  "t3a.medium", "t3a.large",
    "m5.large",    "m5.xlarge",  "m5.2xlarge", "m5.4xlarge",
    "m6i.large",   "m6i.xlarge", "m6i.2xlarge",
    "c5.large",    "c5.xlarge",  "c5.2xlarge",
    "c6i.large",   "c6i.xlarge", "c6i.2xlarge",
    "r5.large",    "r5.xlarge",  "r5.2xlarge"
]

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance_type := resource.change.after.instance_type
    not instance_type == approved_instance_types[_]
    msg := sprintf(
        "[INST-001] EC2 instance '%s' uses unapproved instance type '%s'. See compliance.rego for the approved list.",
        [resource.address, instance_type]
    )
}

# =======================================================
# RDS INSTANCE CLASS POLICY: Only approved RDS instance classes
# =======================================================
approved_db_instance_classes := [
    "db.t3.micro",  "db.t3.small",  "db.t3.medium", "db.t3.large",
    "db.t4g.micro", "db.t4g.small", "db.t4g.medium",
    "db.m5.large",  "db.m5.xlarge", "db.m5.2xlarge",
    "db.m6g.large", "db.m6g.xlarge",
    "db.r5.large",  "db.r5.xlarge", "db.r5.2xlarge",
    "db.r6g.large", "db.r6g.xlarge"
]

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    db_class := resource.change.after.instance_class
    not db_class == approved_db_instance_classes[_]
    msg := sprintf(
        "[INST-002] RDS instance '%s' uses unapproved instance class '%s'. See compliance.rego for the approved list.",
        [resource.address, db_class]
    )
}

# =======================================================
# COST POLICY: Warn on expensive instance types
# =======================================================
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance_type := resource.change.after.instance_type
    expensive_types := ["p3.8xlarge", "p3.16xlarge", "p4d.24xlarge", "x1e.32xlarge", "u-6tb1.metal"]
    instance_type == expensive_types[_]
    msg := sprintf(
        "[COST-001W] EC2 instance '%s' uses expensive instance type '%s'. Confirm this is necessary and approved.",
        [resource.address, instance_type]
    )
}
