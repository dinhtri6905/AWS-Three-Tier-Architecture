package terraform

# ==============================================================
# NETWORKING POLICIES - AWS Three-Tier Architecture
# Covers: VPC, Subnets, Security Groups, ALB, RDS, Auto Scaling
# Evaluated against: terraform plan JSON (terraform show -json)
# ==============================================================

# =======================================================
# NET-001: VPC must have DNS support enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    resource.change.after.enable_dns_support != true
    msg := sprintf(
        "[NET-001] VPC '%s' must have enable_dns_support = true.",
        [resource.address]
    )
}

# =======================================================
# NET-002: VPC must have DNS hostnames enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    resource.change.after.enable_dns_hostnames != true
    msg := sprintf(
        "[NET-002] VPC '%s' must have enable_dns_hostnames = true.",
        [resource.address]
    )
}

# =======================================================
# NET-003: VPC CIDR must use private IP address ranges (RFC 1918)
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    cidr := resource.change.after.cidr_block
    not startswith(cidr, "10.")
    not startswith(cidr, "172.16.")
    not startswith(cidr, "172.17.")
    not startswith(cidr, "172.18.")
    not startswith(cidr, "172.19.")
    not startswith(cidr, "172.20.")
    not startswith(cidr, "172.21.")
    not startswith(cidr, "172.22.")
    not startswith(cidr, "172.23.")
    not startswith(cidr, "172.24.")
    not startswith(cidr, "172.25.")
    not startswith(cidr, "172.26.")
    not startswith(cidr, "172.27.")
    not startswith(cidr, "172.28.")
    not startswith(cidr, "172.29.")
    not startswith(cidr, "172.30.")
    not startswith(cidr, "172.31.")
    not startswith(cidr, "192.168.")
    msg := sprintf(
        "[NET-003] VPC '%s' CIDR block '%s' must be within RFC 1918 private address space.",
        [resource.address, cidr]
    )
}

# =======================================================
# NET-004: All subnets must have a Name tag
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_subnet"
    tags := resource.change.after.tags
    not tags.Name
    msg := sprintf(
        "[NET-004] Subnet '%s' must have a 'Name' tag to identify its tier (web/app/db) and AZ.",
        [resource.address]
    )
}

# =======================================================
# NET-005: Security groups must not expose database ports to 0.0.0.0/0
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    rule := resource.change.after.ingress[_]
    rule.cidr_blocks[_] == "0.0.0.0/0"
    db_port := [3306, 5432, 1433, 27017, 6379, 9200][_]
    rule.from_port <= db_port
    rule.to_port >= db_port
    msg := sprintf(
        "[NET-005] Security group '%s' must not expose database port %d to 0.0.0.0/0.",
        [resource.address, db_port]
    )
}

# =======================================================
# NET-006: Security group rules must not expose database ports to 0.0.0.0/0
# (covers aws_security_group_rule resource type)
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    db_port := [3306, 5432, 1433, 27017, 6379, 9200][_]
    resource.change.after.from_port <= db_port
    resource.change.after.to_port >= db_port
    msg := sprintf(
        "[NET-006] Security group rule '%s' must not expose database port %d to 0.0.0.0/0.",
        [resource.address, db_port]
    )
}

# =======================================================
# NET-007: ALB must be deployed in at least 2 subnets for high availability
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    subnets := resource.change.after.subnets
    count(subnets) < 2
    msg := sprintf(
        "[NET-007] ALB '%s' must be deployed in at least 2 subnets across different Availability Zones.",
        [resource.address]
    )
}

# =======================================================
# NET-008: RDS instances must have Multi-AZ enabled
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.multi_az != true
    msg := sprintf(
        "[NET-008] RDS instance '%s' must have multi_az = true for high availability and failover.",
        [resource.address]
    )
}

# =======================================================
# NET-009: Auto Scaling Groups must span at least 2 Availability Zones
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_autoscaling_group"
    azs := resource.change.after.availability_zones
    count(azs) < 2
    msg := sprintf(
        "[NET-009] Auto Scaling Group '%s' must span at least 2 Availability Zones for resilience.",
        [resource.address]
    )
}

# =======================================================
# NET-010: Auto Scaling Group desired_capacity must be >= min_size
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_autoscaling_group"
    resource.change.after.desired_capacity < resource.change.after.min_size
    msg := sprintf(
        "[NET-010] Auto Scaling Group '%s' desired_capacity (%d) is less than min_size (%d).",
        [
            resource.address,
            resource.change.after.desired_capacity,
            resource.change.after.min_size
        ]
    )
}

# =======================================================
# NET-011: Auto Scaling Group must define health check type
# =======================================================
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_autoscaling_group"
    not resource.change.after.health_check_type
    msg := sprintf(
        "[NET-011] Auto Scaling Group '%s' must define a health_check_type (EC2 or ELB).",
        [resource.address]
    )
}

# =======================================================
# NET-012: Warn if no NAT Gateway is defined
# (private subnets need NAT Gateway for outbound internet access)
# =======================================================
warn contains msg if {
    nat_gateways := [r | r := input.resource_changes[_]; r.type == "aws_nat_gateway"]
    count(nat_gateways) == 0
    msg := "[NET-012W] No NAT Gateway found. EC2 instances in private subnets will not have outbound internet access."
}

# =======================================================
# NET-013: Warn if no VPC flow logs are defined
# =======================================================
warn contains msg if {
    flow_logs := [r | r := input.resource_changes[_]; r.type == "aws_flow_log"]
    count(flow_logs) == 0
    msg := "[NET-013W] No VPC Flow Logs found. Enable VPC Flow Logs for network traffic visibility and audit compliance."
}

# =======================================================
# NET-014: Warn if subnets auto-assign public IP addresses
# (instances should receive IPs explicitly via Elastic IPs)
# =======================================================
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_subnet"
    resource.change.after.map_public_ip_on_launch == true
    msg := sprintf(
        "[NET-014W] Subnet '%s' auto-assigns public IP addresses. Consider assigning Elastic IPs explicitly.",
        [resource.address]
    )
}

# =======================================================
# NET-015: Default VPC should not be used for production resources
# =======================================================
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_default_vpc"
    resource.change.actions[_] == "create"
    msg := "[NET-015W] Default VPC is being used. Create a custom VPC with proper subnet segmentation instead."
}
