# Route53 zone data
data "aws_route53_zone" "public" {
  name         = "example.com"
  private_zone = false
}

# Secret for the DB
data "aws_secretsmanager_secret" "db_password" {
  name = "dev/rds/password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

# KMS follows strict rules. Encryption is mandatory even in dev.
module "kms" {
  source      = "../../modules/kms"
  env         = var.env
  common_tags = var.common_tags
  ecr_allowed_read_principals = [module.eks.node_iam_role_arn]
}

# Network (2 AZ for savings, but with IPv6 support as in prod)
module "vpc" {
  source             = "../../modules/vpc"
  env                = var.env
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]

  log_bucket_id      = module.monitoring.cloudtrail_logs_bucket_id
  kms_key_arn        = module.kms.s3_key_arn

  enable_ipv6        = true
  assign_generated_ipv6_cidr_block = true
}

# Database
module "rds" {
  source = "../../modules/rds"

  env            = var.env
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_app_subnets
  kms_key_arn    = module.kms.rds_key_arn

  instance_class = "db.t3.micro"
  db_name        = "example_dev"
  db_username    = var.db_username
  db_password    = data.aws_secretsmanager_secret_version.db_password.secret_string

  multi_az       = false # Экономия стоимости
  allocated_storage     = 20
  max_allocated_storage = 50

  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  allowed_security_groups = [module.eks.node_security_group_id]
}

# Kubernetes
module "eks" {
  source = "../../modules/eks"

  env          = var.env
  cluster_name = "example-dev-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_app_subnets
  kms_key_arn  = module.kms.eks_key_arn

  kubernetes_networking_config = { ip_family = "ipv6" }

  node_groups = {
    main = {
      instance_types = ["t3.medium"]
      desired_size   = 1
      min_size       = 1
      max_size       = 3
    }
  }
}

# Monitoring and Security
module "monitoring" {
  source             = "../../modules/monitoring"
  env                = var.env
  notification_email = "dev-security@example.com"
  kms_key_arn        = module.kms.monitoring_key_arn
}

module "waf" {
  source      = "../../modules/waf"
  env         = var.env
  kms_key_arn = module.kms.s3_key_arn
}

module "aws_backup" {
  source      = "../../modules/aws_backup"
  env         = var.env
  kms_key_arn = module.kms.s3_key_arn
  sns_kms_key_arn = module.kms.monitoring_key_arn
  notification_email = "dev-alerts@example.com"
  common_tags = var.common_tags
}

# Ancillary services
module "acm" {
  source      = "../../modules/acm"
  env         = var.env
  common_tags = var.common_tags
  domain_name = "dev.api.example.com"
  zone_id     = data.aws_route53_zone.public.zone_id
}

module "s3_medical_data" {
  source = "../../modules/s3"
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }
  env           = var.env
  kms_key_arn   = module.kms.s3_key_arn
  kms_key_arn_secondary = module.kms.s3_key_arn
  log_bucket_id = module.vpc.flow_log_bucket_id
}

module "iam_roles_irsa" {
  source            = "../../modules/iam_roles_irsa"
  env               = var.env
  cluster_name      = module.eks.cluster_name
  oidc_provider     = module.eks.oidc_provider
  oidc_provider_arn = module.eks.oidc_provider_arn

  kms_key_arn        = module.kms.s3_key_arn
  phi_s3_bucket_arn  = module.s3_medical_data.bucket_arn
  velero_bucket_name = "dev-example-backups"
  external_dns_zone_arns = [data.aws_route53_zone.public.arn]
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"
  env             = var.env
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = module.vpc.vpc_cidr
  subnet_ids      = module.vpc.private_app_subnets
  route_table_ids = concat([module.vpc.public_route_table_id], module.vpc.private_route_table_ids)
  common_tags = var.common_tags
}

# Role for Enhanced Monitoring RDS
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-dev-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}