terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

# KMS key for state encryption
resource "aws_kms_key" "terraform_state" {
  description = "KMS key for Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation = true
  tags = var.common_tags
}

resource "aws_kms_alias" "terraform_state" {
  name = "alias/terraform-state-key"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# S3 bucket for state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "GenovaX-terraform-state-storage"

  # Protection against accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = var.common_tags
}

# forced SSL (Encryption in Transit) policy
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyInsecureTransport"
      Effect = "Deny"
      Principal = "*"
      Action = "s3:*"
      Resource = [
        aws_s3_bucket.terraform_state.arn,
        "${aws_s3_bucket.terraform_state.arn}/*"
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

# Versioning
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# DynamoDB for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name = "GenovaX-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.common_tags
}