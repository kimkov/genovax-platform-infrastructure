data "aws_route53_zone" "public" {
  name         = "example.com"
  private_zone = false
}

# ACM
module "acm" {
  source      = "../../modules/acm"
  env         = var.env
  common_tags = var.common_tags

  domain_name               = "api.example.com"
  subject_alternative_names = ["*.example.com"]
  zone_id                   = data.aws_route53_zone.public.zone_id
}

# Network with dual-stack enabled (IPv4 + IPv6)
module "vpc" {
  source = "../../modules/vpc"

  env                 = var.env
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  log_bucket_id      = module.monitoring.cloudtrail_logs_bucket_id
  kms_key_arn         = module.kms.s3_key_arn

  # Dual-stack configuration
  enable_ipv6                       = true
  assign_generated_ipv6_cidr_block  = true
}

# WAF
module "waf" {
  source      = "../../modules/waf"
  env         = var.env
  common_tags = var.common_tags
  kms_key_arn = module.kms.s3_key_arn # We use the key from the KMS module
}

# Monitoring module (creates Log Group)
module "monitoring" {
  source             = "../../modules/monitoring"
  env                = var.env
  notification_email = "security-officer@example.com"
  common_tags        = var.common_tags
  kms_key_arn        = module.kms.monitoring_key_arn

  alb_arn_suffix = ""
  eks_cluster_name = module.eks.cluster_name
}

# DataBase (RDS) in Dual-stack mode
module "rds" {
  source = "../../modules/rds"

  env                   = var.env
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_app_subnets
  kms_key_arn           = module.kms.rds_key_arn

  # Engine & Instance configuration
  engine_version        = "18.1"
  instance_class        = "db.r6g.large"
  db_name               = "example_prod"
  db_username           = var.db_username

  # Security: Password from Secrets Manager
  db_password           = data.aws_secretsmanager_secret_version.db_password.secret_string

  # Networking
  network_type          = "DUAL"
  multi_az              = true
  publicly_accessible   = false

  # Monitoring (HIPAA Requirement)
  monitoring_role_arn   = aws_iam_role.rds_monitoring.arn

  allowed_security_groups = [module.eks.node_security_group_id]
}

# Kubernetes (EKS) with IPv6
module "eks" {
  source = "../../modules/eks"

  env                   = var.env
  cluster_name          = "example-prod-cluster"
  vpc_id                = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_app_subnets
  kms_key_arn  = module.kms.eks_key_arn

  # EKS Pod networking using IPv6
  kubernetes_networking_config = {
    ip_family           = "ipv6"
  }

  node_groups = {
    main = {
      desired_size = 3
      min_size     = 3
      max_size     = 10
    }
  }

  # Isolating PHI data with Fargate
  fargate_profiles = {
    phi_processing = {
      name = "phi-processing"
      selectors = [
        {
          namespace = "phi-apps"
        }
      ]
    }
  }
}

# EKS Addons module (deploys Fluent-bit via Helm)
module "eks_addons" {
  source = "../../modules/eks_addons"

  aws_region = var.aws_region
  fluent_bit_role_arn = module.iam_roles_irsa.fluent_bit_role_arn
  log_group_name = module.monitoring.eks_container_log_group_name

  depends_on = [
    module.eks,
    module.iam_roles_irsa,
    module.monitoring
  ]
}

module "ecr" {
  source = "../../modules/ecr"

  env              = var.env
  common_tags      = var.common_tags
  kms_key_arn      = module.kms.ecr_key_arn

  repository_names = [
    "example/api-gateway",
    "example/phi-processor",
    "example/auth-service"
  ]

  #Allowing EKS nodes to download images
  allowed_read_principals = [module.eks.node_iam_role_arn]
}

# Kubernetes Resources for HIPAA & Operations
resource "kubernetes_namespace" "phi_apps" {
  metadata {
    name = "phi-apps"
    labels = {
      purpose = "phi-processing"
    }
  }
}

resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
}

module "kms" {
  source = "../../modules/kms"
  env    = var.env

  # Allowing EKS nodes to use the ECR key
  ecr_allowed_read_principals = [module.eks.node_iam_role_arn]
  common_tags                 = var.common_tags
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

# Retrieving a secret from AWS Secrets Manager
data "aws_secretsmanager_secret" "db_password" {
  name = "prod/rds/password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

# Creating an IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-enhanced-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# AWS Load Balancer Controller (Ingress)
module "iam_roles_irsa" {
  source = "../../modules/iam_roles_irsa"

  env               = var.env
  cluster_name      = module.eks.cluster_name
  oidc_provider     = module.eks.oidc_provider
  oidc_provider_arn = module.eks.oidc_provider_arn
  common_tags       = var.common_tags

  kms_key_arn        = module.kms.s3_key_arn
  velero_bucket_name = "${var.env}-example-velero-backups"
  phi_s3_bucket_arn  = module.s3_medical_data.bucket_arn
  external_dns_zone_arns = [data.aws_route53_zone.public.arn]
}

module "alb_controller" {
  source            = "../../modules/alb"
  cluster_name      = module.eks.cluster_name
  vpc_id            = module.vpc.vpc_id
  aws_region        = var.aws_region
  role_arn          = module.iam_roles_irsa.lbc_role_arn
}
module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  env             = var.env
  common_tags     = var.common_tags
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = module.vpc.vpc_cidr
  subnet_ids      = module.vpc.private_app_subnets
  route_table_ids = concat([module.vpc.public_route_table_id], module.vpc.private_route_table_ids)
}
module "aws_backup" {
  source = "../../modules/aws_backup"

  env         = var.env
  common_tags = var.common_tags

  kms_key_arn        = module.kms.s3_key_arn # Using S3 key or common encryption key
  sns_kms_key_arn = module.kms.monitoring_key_arn
  notification_email = "security-officer@example.com"
}
