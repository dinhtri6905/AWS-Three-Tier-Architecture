# policies/networking.rego
#
# Bao ve cau truc mang cho AWS Three-Tier Architecture.
# Dam bao tach biet tang (Web public / App private / DB private),
# kiem soat routing va security group giua cac tang.
#
# deny  -> vi pham cau truc mang, block deploy
# warn  -> canh bao thiet ke, khong block deploy

package terraform.networking

# =============================================================================
# VPC - Cau hinh co ban
# =============================================================================

# VPC phai bat DNS hostnames (can thiet cho RDS endpoint va service discovery)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    resource.change.after.enable_dns_hostnames == false
    msg := sprintf(
        "VPC '%s': enable_dns_hostnames phai la true (can cho RDS endpoint va service discovery)",
        [resource.address]
    )
}

# VPC phai bat DNS support (resolution)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    resource.change.after.enable_dns_support == false
    msg := sprintf(
        "VPC '%s': enable_dns_support phai la true",
        [resource.address]
    )
}

# =============================================================================
# Subnet - Phan tach public/private
# =============================================================================

# Subnet co tag Tier=app khong duoc map public IP
# (App tier phai nam o private subnet, chi ALB o public)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_subnet"
    resource.change.after.map_public_ip_on_launch == true
    resource.change.after.tags.Tier == "app"
    msg := sprintf(
        "Subnet '%s' (Tier=app): map_public_ip_on_launch phai la false - App tier phai o private subnet",
        [resource.address]
    )
}

# Subnet co tag Tier=database khong duoc map public IP
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_subnet"
    resource.change.after.map_public_ip_on_launch == true
    resource.change.after.tags.Tier == "database"
    msg := sprintf(
        "Subnet '%s' (Tier=database): map_public_ip_on_launch phai la false - DB tier phai o private subnet",
        [resource.address]
    )
}

# =============================================================================
# EC2 - App tier khong duoc co public IP
# =============================================================================

# EC2 instance o App tier khong duoc associate public IP
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    resource.change.after.associate_public_ip_address == true
    resource.change.after.tags.Tier == "app"
    msg := sprintf(
        "EC2 instance '%s' (Tier=app): associate_public_ip_address phai la false - chi Web tier moi duoc public IP",
        [resource.address]
    )
}

# =============================================================================
# RDS - Network isolation
# =============================================================================

# RDS phai duoc dat trong DB subnet group (khong deploy tren public subnet)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    not resource.change.after.db_subnet_group_name
    msg := sprintf(
        "RDS instance '%s': phai co db_subnet_group_name - RDS phai nam trong private subnet group",
        [resource.address]
    )
}

# =============================================================================
# ALB - Cau hinh Web tier
# =============================================================================

# ALB cua Web tier phai la internet-facing
# (internal ALB dung cho App tier, internet-facing cho Web tier)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    resource.change.after.tags.Tier == "web"
    resource.change.after.internal == true
    msg := sprintf(
        "ALB '%s' (Tier=web): internal phai la false - Web tier ALB phai la internet-facing de nhan traffic tu internet",
        [resource.address]
    )
}

# ALB phai co it nhat 2 subnet (multi-AZ de High Availability)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    count(resource.change.after.subnets) < 2
    msg := sprintf(
        "ALB '%s': phai deploy tren it nhat 2 subnet (multi-AZ) de dam bao High Availability",
        [resource.address]
    )
}

# =============================================================================
# Security Group - Phan luong traffic giua cac tang
# =============================================================================

# Security group phai co description ro rang (khong de trong hoac default)
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group"
    desc := resource.change.after.description
    lower(desc) == "managed by terraform"
    msg := sprintf(
        "Security Group '%s': description '%s' qua chung, hay mo ta ro chuc nang (vi du: 'Web tier - allow HTTP/HTTPS from internet')",
        [resource.address, desc]
    )
}

# Security group egress chi nen cho phep cac port can thiet,
# khong cho phep all egress ma khong co ly do
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "egress"
    resource.change.after.protocol == "-1"
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    resource.change.after.tags.Tier == "database"
    msg := sprintf(
        "Security Group Rule '%s': DB tier khong nen co unrestricted egress (protocol=-1, 0.0.0.0/0)",
        [resource.address]
    )
}

# =============================================================================
# WARN - Canh bao thiet ke mang, khong block deploy
# =============================================================================

# VPC nen bat Flow Logs de ghi lai network traffic (audit, debug)
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    not resource.change.after.tags.FlowLogs
    msg := sprintf(
        "[WARN] VPC '%s': nen tao aws_flow_log resource de bat VPC Flow Logs (ho tro audit va debug)",
        [resource.address]
    )
}

# ALB nen dung HTTPS (443) de ma hoa traffic giua client va load balancer
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb_listener"
    resource.change.after.port != 443
    resource.change.after.tags.Tier == "web"
    msg := sprintf(
        "[WARN] ALB Listener '%s': nen su dung port 443 (HTTPS) thay vi HTTP de ma hoa traffic",
        [resource.address]
    )
}

# NAT Gateway nen duoc tao cho private subnet (App tier can truy cap internet update package)
warn contains msg if {
    resources := [r | r := input.resource_changes[_]; r.type == "aws_nat_gateway"]
    count(resources) == 0
    msg := "Khong tim thay aws_nat_gateway - App tier va DB tier co the khong truy cap duoc internet de update package"
}
