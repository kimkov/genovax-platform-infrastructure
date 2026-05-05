locals {
  interface_endpoints = toset([
    "ecr.api",
    "ecr.dkr",
    "secretsmanager",
    "logs",
    "kms",
    "sts",
    "ec2",
    "elasticloadbalancing",
    "autoscaling",
    "monitoring",
    "xray"
  ])
}

# Gateway Endpoints (S3 и DynamoDB)
resource "aws_vpc_endpoint" "gateway_endpoints" {
  for_each          = toset(["s3", "dynamodb"])
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.route_table_ids

  tags = merge(var.common_tags, { Name = "${var.env}-${each.value}-endpoint" })
}

# Interface Endpoints (PrivateLink) with security policies
resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "*"
      Effect    = "Allow"
      Principal = "*"
      Resource  = "*"
      Condition = {
        StringEquals = {
          "aws:PrincipalAccount" = [data.aws_caller_identity.current.account_id]
        }
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.env}-${replace(each.value, ".", "-")}-endpoint"
  })
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.env}-vpc-endpoints-sg"
  description = "Strict security group for VPC Endpoints (HIPAA Hardened)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTPS only from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow response traffic back to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.common_tags, { Name = "${var.env}-vpc-endpoints-sg" })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
