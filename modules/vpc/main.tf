locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ===== VPC =====
resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_12: Default security group not used in this architecture
  #checkov:skip=CKV2_AWS_11: VPC Flow Logs not required for lab environment

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ===== INTERNET GATEWAY =====
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ===== PUBLIC SUBNETS =====
resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130: Public subnet required for internet-facing ALB

  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
    Tier = "Public"
  }
}

# ===== PRIVATE APP SUBNETS =====
resource "aws_subnet" "app" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-app-subnet-${count.index + 1}"
    Tier = "Application"
  }
}

# ===== PRIVATE DB SUBNETS =====
resource "aws_subnet" "db" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-db-subnet-${count.index + 1}"
    Tier = "Database"
  }
}

# ===== ELASTIC IPs cho NAT GATEWAYS =====
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ===== NAT GATEWAYS (1 per AZ for High Availability) =====
resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

# ===== PUBLIC ROUTE TABLE =====
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ===== PRIVATE APP ROUTE TABLE =====
resource "aws_route_table" "app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${local.name_prefix}-app-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "app" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

# ===== PRIVATE DB ROUTE TABLE =====
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-db-rt"
  }
}

resource "aws_route_table_association" "db" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}
