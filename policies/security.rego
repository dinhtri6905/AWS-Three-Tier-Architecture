# policies/security.rego
#
# Bao ve tang bao mat cho AWS Three-Tier Architecture.
# Resources duoc kiem tra: EC2, Launch Template, RDS, ALB, Security Group, IAM.
#
# deny  -> vi pham nghiem trong, block deploy
# warn  -> canh bao, khong block deploy nhung ghi vao log

package terraform.security

# =============================================================================
# EC2 - Bat buoc IMDSv2 (chong SSRF attack)
# =============================================================================

# EC2 instance phai enforce IMDSv2 (http_tokens = "required")
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    metadata := resource.change.after.metadata_options[_]
    metadata.http_tokens != "required"
    msg := sprintf(
        "EC2 instance '%s': metadata_options.http_tokens phai la 'required' de enforce IMDSv2",
        [resource.address]
    )
}

# Launch Template phai enforce IMDSv2 (dung cho Auto Scaling Group)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_launch_template"
    metadata := resource.change.after.metadata_options[_]
    metadata.http_tokens != "required"
    msg := sprintf(
        "Launch Template '%s': metadata_options.http_tokens phai la 'required' de enforce IMDSv2",
        [resource.address]
    )
}

# =============================================================================
# RDS - Ma hoa, public access, backup
# =============================================================================

# RDS phai bat ma hoa storage
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted == false
    msg := sprintf(
        "RDS instance '%s': storage_encrypted phai la true",
        [resource.address]
    )
}

# RDS khong duoc public (Data tier nam o private subnet)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.publicly_accessible == true
    msg := sprintf(
        "RDS instance '%s': publicly_accessible phai la false - Data tier chi duoc truy cap tu App tier",
        [resource.address]
    )
}

# RDS phai co backup retention >= 7 ngay
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.backup_retention_period < 7
    msg := sprintf(
        "RDS instance '%s': backup_retention_period = %d, yeu cau >= 7 ngay",
        [resource.address, resource.change.after.backup_retention_period]
    )
}

# =============================================================================
# Security Group - Kiem soat cac port nhay cam
# =============================================================================

# Khong cho phep SSH (22) tu 0.0.0.0/0 (ingress rule resource)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.from_port <= 22
    resource.change.after.to_port >= 22
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "Security Group Rule '%s': SSH (port 22) khong duoc mo ra internet (0.0.0.0/0)",
        [resource.address]
    )
}

# Khong cho phep RDP (3389) tu 0.0.0.0/0
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.from_port <= 3389
    resource.change.after.to_port >= 3389
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "Security Group Rule '%s': RDP (port 3389) khong duoc mo ra internet (0.0.0.0/0)",
        [resource.address]
    )
}

# Khong cho phep all traffic (-1) ingress tu 0.0.0.0/0
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.protocol == "-1"
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "Security Group Rule '%s': khong duoc cho phep tat ca traffic (protocol=-1) tu 0.0.0.0/0",
        [resource.address]
    )
}

# Khong cho phep MySQL (3306) tu 0.0.0.0/0
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.from_port <= 3306
    resource.change.after.to_port >= 3306
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "Security Group Rule '%s': MySQL port 3306 khong duoc mo ra internet (0.0.0.0/0)",
        [resource.address]
    )
}

# Khong cho phep PostgreSQL (5432) tu 0.0.0.0/0
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.from_port <= 5432
    resource.change.after.to_port >= 5432
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf(
        "Security Group Rule '%s': PostgreSQL port 5432 khong duoc mo ra internet (0.0.0.0/0)",
        [resource.address]
    )
}

# =============================================================================
# IAM - Quyen han toi thieu (Least Privilege)
# =============================================================================

# IAM policy khong duoc co Action=* va Resource=* dong thoi (full admin)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action[_] == "*"
    statement.Resource[_] == "*"
    msg := sprintf(
        "IAM Policy '%s': khong duoc cap quyen Action=* tren Resource=* (full admin permissions)",
        [resource.address]
    )
}

# IAM policy (string format) khong duoc Action=* va Resource=*
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    statement.Effect == "Allow"
    statement.Action == "*"
    statement.Resource == "*"
    msg := sprintf(
        "IAM Policy '%s': khong duoc cap quyen Action=* tren Resource=* (full admin permissions)",
        [resource.address]
    )
}

# Khong gan IAM inline policy truc tiep vao IAM user
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_user_policy"
    msg := sprintf(
        "IAM User Policy '%s': khong gan policy truc tiep vao user, hay dung IAM Group hoac Role",
        [resource.address]
    )
}

# =============================================================================
# WARN - Canh bao, khong block deploy
# =============================================================================

# ALB nen bat access logs de audit
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    not resource.change.after.access_logs
    msg := sprintf(
        "[WARN] ALB '%s': nen bat access_logs de ghi lai request (audit purpose)",
        [resource.address]
    )
}

# RDS nen bat deletion_protection de tranh xoa nham
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.deletion_protection == false
    msg := sprintf(
        "[WARN] RDS '%s': nen bat deletion_protection = true de tranh xoa nham",
        [resource.address]
    )
}

# EC2 App tier nen dung key pair
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    not resource.change.after.key_name
    msg := sprintf(
        "[WARN] EC2 instance '%s': khong co key_name, dam bao co phuong thuc khac de truy cap (SSM Session Manager)",
        [resource.address]
    )
}
