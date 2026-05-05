terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = merge(var.common_tags, {
    Name = "${var.env}-vpc"
    Owner = var.owner
  })
}

# Hardened Default Security Group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.common_tags, {
    Name = "${var.env}-default-sg-locked"
  })
}

# Flow Logs
resource "aws_flow_log" "main" {
  log_destination = "arn:aws:s3:::${var.log_bucket_id}"
  log_destination_type = "s3"
  traffic_type = "ALL"
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.env}-vpc-flow-logs"})
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.common_tags, {
    Name = "${var.env}-igw"
  })
}

# Egress Only Internet Gateway (IPv6 Security)
resource "aws_egress_only_internet_gateway" "main" {
  count = var.enable_ipv6 ? 1 : 0
  vpc_id = aws_vpc.main.id
  tags = merge(var.common_tags, {
    Name = "${var.env}-eoigw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index)

  ipv6_cidr_block = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index) : null

  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.env}-public-${count.index}"
    "kubernetes.io/role/elb" = "1"
  })
}

# NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"
  tags   = merge(var.common_tags, { Name = "${var.env}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(var.common_tags, { Name = "${var.env}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.main]
}

# Private Subnets (App Layer)
resource "aws_subnet" "private_app" {
  count = length(var.availability_zones)
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 4)

  ipv6_cidr_block = var.enable_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 4) : null

  availability_zone = var.availability_zones[count.index]
  tags = merge(var.common_tags, {
    Name = "${var.env}-private-app-${count.index}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Routing

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  dynamic "route" {
    for_each = var.enable_ipv6 ? [1] : []
    content {
      ipv6_cidr_block = "::/0"
      gateway_id = aws_internet_gateway.main.id
    }
  }

  tags = merge(var.common_tags, { Name = "${var.env}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for NAT redundancy)
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  dynamic "route" {
    for_each = var.enable_ipv6 ? [1] : []
    content {
      ipv6_cidr_block = "::/0"
      egress_only_gateway_id = aws_egress_only_internet_gateway.main[0].id
    }
  }

  tags = merge(var.common_tags, { Name = "${var.env}-private-rt-${count.index}" })
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Network ACLs

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private_app[*].id

  # Ingress: Allow internal VPC traffic
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Egress: Limiting outgoing traffic (Example: HTTPS and DNS)
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "udp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }

  # Allowing ephemeral ports to respond to incoming requests
  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(var.common_tags, { Name = "${var.env}-private-nacl" })
}

# Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_app_subnets" {
  value = aws_subnet.private_app[*].id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "flow_log_bucket_id" {
  value = var.log_bucket_id # Using the ARN as ID here, or if you need the actual name, you'd need another var
}
output "vpc_cidr" {
  value = var.vpc_cidr
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}
