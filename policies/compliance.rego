# policies/compliance.rego
#
# CIS AWS Foundations Benchmark cho AWS Three-Tier Architecture.
# Tham chieu: CIS Amazon Web Services Foundations Benchmark v1.5.0
#
# Cac section duoc kiem tra:
#   CIS 2.x - Storage (S3)
#   CIS 3.x - Logging (CloudTrail)
#   CIS 4.x - Monitoring (CloudWatch)
#   CIS 5.x - Identity and Access Management (IAM)
#
# deny  -> vi pham CIS, block deploy
# warn  -> khuyen nghi CIS, khong block deploy

package terraform.compliance

# =============================================================================
# CIS 2.1 - S3 (Terraform State Bucket)
# =============================================================================

# CIS 2.1.1: S3 phai bat server-side encryption
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.server_side_encryption_configuration
    msg := sprintf(
        "[CIS 2.1.1] S3 bucket '%s': phai bat server-side encryption (SSE-S3 hoac SSE-KMS)",
        [resource.address]
    )
}

# CIS 2.1.2: S3 phai bat versioning
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_versioning"
    resource.change.after.versioning_configuration.status != "Enabled"
    msg := sprintf(
        "[CIS 2.1.2] S3 bucket '%s': versioning_configuration.status phai la 'Enabled'",
        [resource.address]
    )
}

# CIS 2.1.3: S3 phai block public access
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.block_public_acls != true
    msg := sprintf(
        "[CIS 2.1.3] S3 bucket '%s': block_public_acls phai la true",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.block_public_policy != true
    msg := sprintf(
        "[CIS 2.1.3] S3 bucket '%s': block_public_policy phai la true",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.ignore_public_acls != true
    msg := sprintf(
        "[CIS 2.1.3] S3 bucket '%s': ignore_public_acls phai la true",
        [resource.address]
    )
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.change.after.restrict_public_buckets != true
    msg := sprintf(
        "[CIS 2.1.3] S3 bucket '%s': restrict_public_buckets phai la true",
        [resource.address]
    )
}

# =============================================================================
# CIS 3.x - Logging (CloudTrail)
# =============================================================================

# CIS 3.1: Phai co it nhat 1 CloudTrail trail duoc bat
deny contains msg if {
    trails := [r | r := input.resource_changes[_]; r.type == "aws_cloudtrail"]
    count(trails) == 0
    msg := "[CIS 3.1] Khong tim thay aws_cloudtrail resource - phai co it nhat 1 CloudTrail trail"
}

# CIS 3.2: CloudTrail phai bat log file validation
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudtrail"
    resource.change.after.enable_log_file_validation == false
    msg := sprintf(
        "[CIS 3.2] CloudTrail '%s': enable_log_file_validation phai la true de dam bao tinh toan ven cua log file",
        [resource.address]
    )
}

# CIS 3.4: CloudTrail phai tich hop voi CloudWatch Logs
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudtrail"
    not resource.change.after.cloud_watch_logs_group_arn
    msg := sprintf(
        "[CIS 3.4] CloudTrail '%s': phai co cloud_watch_logs_group_arn de gui log vao CloudWatch",
        [resource.address]
    )
}

# CIS 3.5: CloudTrail phai bat cho tat ca cac region
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudtrail"
    resource.change.after.is_multi_region_trail == false
    msg := sprintf(
        "[CIS 3.5] CloudTrail '%s': is_multi_region_trail phai la true de ghi log tu tat ca region",
        [resource.address]
    )
}

# =============================================================================
# CIS 5.x - Identity and Access Management (IAM)
# =============================================================================

# CIS 5.1: Khong gan IAM policy truc tiep vao IAM user
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_user_policy"
    msg := sprintf(
        "[CIS 5.1] IAM User Policy '%s': khong duoc gan policy truc tiep vao user, hay su dung IAM Group hoac Role",
        [resource.address]
    )
}

# CIS 5.1: Khong dung aws_iam_policy_attachment voi user (chi dung cho group/role)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy_attachment"
    count(resource.change.after.users) > 0
    msg := sprintf(
        "[CIS 5.1] IAM Policy Attachment '%s': users = %v, phai gan policy qua Group hoac Role",
        [resource.address, resource.change.after.users]
    )
}

# CIS 5.2: IAM policy khong duoc cap full permissions (Action=*, Resource=*)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action == "*"
    statement.Resource == "*"
    msg := sprintf(
        "[CIS 5.2] IAM Policy '%s': vi pham full permissions (Action=*, Resource=*)",
        [resource.address]
    )
}

# CIS 5.4: RDS phai bat ma hoa (luu tru)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted != true
    msg := sprintf(
        "[CIS 5.4] RDS instance '%s': storage_encrypted phai la true",
        [resource.address]
    )
}

# =============================================================================
# Tagging Policy - Bat buoc tag tren cac resource chinh
# Giup quan ly chi phi, trach nhiem va moi truong
# =============================================================================

# Cac resource type bat buoc phai co tags
taggable_resources := {
    "aws_instance",
    "aws_db_instance",
    "aws_lb",
    "aws_vpc",
    "aws_subnet",
    "aws_security_group",
    "aws_s3_bucket"
}

# Resource trong danh sach phai co truong tags
deny contains msg if {
    resource := input.resource_changes[_]
    taggable_resources[resource.type]
    not resource.change.after.tags
    msg := sprintf(
        "Resource '%s' (%s): phai co tags voi cac key: Environment, Project, ManagedBy",
        [resource.address, resource.type]
    )
}

# Resource phai co tag Environment
deny contains msg if {
    resource := input.resource_changes[_]
    taggable_resources[resource.type]
    tags := resource.change.after.tags
    tags
    not tags.Environment
    msg := sprintf(
        "Resource '%s' (%s): thieu tag 'Environment' (gia tri: dev | staging | prod)",
        [resource.address, resource.type]
    )
}

# Resource phai co tag Project
deny contains msg if {
    resource := input.resource_changes[_]
    taggable_resources[resource.type]
    tags := resource.change.after.tags
    tags
    not tags.Project
    msg := sprintf(
        "Resource '%s' (%s): thieu tag 'Project'",
        [resource.address, resource.type]
    )
}

# Resource phai co tag ManagedBy = Terraform
deny contains msg if {
    resource := input.resource_changes[_]
    taggable_resources[resource.type]
    tags := resource.change.after.tags
    tags
    not tags.ManagedBy
    msg := sprintf(
        "Resource '%s' (%s): thieu tag 'ManagedBy' (gia tri: Terraform)",
        [resource.address, resource.type]
    )
}

# =============================================================================
# WARN - Khuyen nghi CIS, khong block deploy
# =============================================================================

# CIS 2.1.4 (warn): S3 nen bat access logging de ghi lai request
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.logging
    msg := sprintf(
        "[WARN][CIS 2.1.4] S3 bucket '%s': nen bat logging de ghi lai access request",
        [resource.address]
    )
}

# CIS 4.1 (warn): nen co CloudWatch alarm cho unauthorized API calls
warn contains msg if {
    alarms := [r | r := input.resource_changes[_]; r.type == "aws_cloudwatch_metric_alarm"]
    count(alarms) == 0
    msg := "[WARN][CIS 4.1] Khong tim thay aws_cloudwatch_metric_alarm - nen thiet lap alarm cho unauthorized API calls"
}

# RDS nen bat multi_az de High Availability (quan trong cho production)
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.multi_az == false
    msg := sprintf(
        "[WARN] RDS instance '%s': multi_az = false, nen bat de dam bao High Availability",
        [resource.address]
    )
}

# Auto Scaling Group nen co it nhat 2 AZ
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_autoscaling_group"
    count(resource.change.after.availability_zones) < 2
    msg := sprintf(
        "[WARN] Auto Scaling Group '%s': chi co 1 AZ, nen trai tren >= 2 AZ de HA",
        [resource.address]
    )
}
