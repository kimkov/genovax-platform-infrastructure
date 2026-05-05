# Creating a log bucket (required for the s3 module)
resource "aws_s3_bucket" "logs" {
  bucket = "local-example-logs"
}

# KMS - Encryption is mandatory even locally
module "kms" {
  source = "../../modules/kms"
  env = var.env
  common_tags = var.common_tags

  # Stub for the EKS role (not used locally, but required by the module)
  ecr_allowed_read_principals = ["arn:aws:iam::000000000000:root"]
}

# S3 Buckets for medical data
module "s3_medical_data" {
  source = "../../modules/s3"

  providers = {
    aws = aws
    aws.secondary = aws.secondary
  }

  env           = var.env
  kms_key_arn   = module.kms.s3_key_arn
  kms_key_arn_secondary = module.kms.s3_key_arn
  log_bucket_id = aws_s3_bucket.logs.id

  common_tags = var.common_tags
}

# Cognito for authentication
module "cognito" {
  source = "../../modules/cognito"
  env = var.env

  user_pool_name = "example-local-users"
  office365_idp_metadata_url = "https://example.com/mock-metadata.xml" # Plug

  common_tags = var.common_tags
}

# Secrets Manager (for storing the database password that the application searches for at startup)
resource "aws_secretsmanager_secret" "db_password" {
  name = "local/rds/password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = "localpassword123"
}

# SQS and SNS
resource "aws_sqs_queue" "audit_queue" {
  name = "local-audit-logs-queue"
}

resource "aws_sns_topic" "alerts" {
  name = "local-system-alerts"
}