terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Data source for obtaining account ID
data "aws_caller_identity" "current" {}

# RDS (Database Encryption) Key
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  enable_key_rotation     = true
  multi_region            = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.rds_kms_policy.json

  tags = merge(var.common_tags, {
    Name = "${var.env}-rds-key"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.env}/rds"
  target_key_id = aws_kms_key.rds.key_id
}

data "aws_iam_policy_document" "rds_kms_policy" {
  statement {
    sid    = "EnableAdminAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowRDSService"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

# KEY FOR EKS (Secrets Encryption)
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS secrets encryption"
  enable_key_rotation     = true
  multi_region            = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.eks_kms_policy.json

  tags = merge(var.common_tags, {
    Name = "${var.env}-eks-key"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.env}/eks"
  target_key_id = aws_kms_key.eks.key_id
}

data "aws_iam_policy_document" "eks_kms_policy" {
  statement {
    sid    = "EnableAdminAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Decryption permission for EKS and CI/CD nodes
  dynamic "statement" {
    for_each = var.eks_node_role_arn != null ? [1] : []
    content {
      sid    = "AllowECRDecrypt"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions   = ["kms:Decrypt", "kms:DescribeKey"]
      resources = ["*"]

      condition {
        test     = "ArnLike"
        values = var.ecr_allowed_read_principals
        variable = "aws:PrincipalArn"
      }
    }
  }
}

# KEY FOR S3 (Medical Data / ePHI)
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 medical data (HIPAA)"
  enable_key_rotation     = true
  multi_region            = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.s3_kms_policy.json

  tags = merge(var.common_tags, { Name = "${var.env}-s3-key" })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.env}/s3"
  target_key_id = aws_kms_key.s3.key_id
}

data "aws_iam_policy_document" "s3_kms_policy" {
  statement {
    sid    = "EnableAdminAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowS3Service"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.s3_replication_role_arn != null ? [1] : []
    content {
      sid    = "AllowS3Replication"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [var.s3_replication_role_arn]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ]
      resources = ["*"]
    }
  }
}

# KEY FOR MONITORING (CloudTrail, Config)
resource "aws_kms_key" "monitoring" {
  description             = "KMS key for CloudTrail and Config logs (HIPAA)"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.monitoring_kms_policy.json

  tags = merge(var.common_tags, { Name = "${var.env}-monitoring-key" })
}

resource "aws_kms_alias" "monitoring" {
  name          = "alias/${var.env}/monitoring"
  target_key_id = aws_kms_key.monitoring.key_id
}

data "aws_iam_policy_document" "monitoring_kms_policy" {
  statement {
    sid    = "EnableAdminAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailService"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*", "kms:Decrypt"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowConfigService"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*", "kms:Decrypt"]
    resources = ["*"]
  }
}

# ECR
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR image encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.ecr_kms_policy.json
  tags                    = var.common_tags
}

# The policy must allow the ECR service to use the key
data "aws_iam_policy_document" "ecr_kms_policy" {
  statement {
    sid    = "EnableAdminAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Decryption permission for EKS nodes
  dynamic "statement" {
    for_each = length(var.ecr_allowed_read_principals) > 0 ? [1] : []
    content {
      sid    = "AllowECRDecrypt"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      condition {
        test     = "ArnLike"
        variable = "aws:PrincipalArn"
        values   = var.ecr_allowed_read_principals
      }
    }
  }
}