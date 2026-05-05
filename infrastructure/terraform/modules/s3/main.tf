terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.secondary]
    }
  }
}

# --- PRIMARY BUCKET ---

resource "aws_s3_bucket" "medical_data" {
  bucket              = "${var.env}-platform-medical-data"
  force_destroy       = false
  object_lock_enabled = true

  tags = merge(var.common_tags, {
    Name      = "${var.env}-platform-medical-data"
    DataClass = "ePHI"
  })
}

resource "aws_s3_bucket_versioning" "medical_data" {
  bucket = aws_s3_bucket.medical_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ИСПРАВЛЕННЫЙ РЕСУРС (был aws_s3_account_public_access_block)
resource "aws_s3_bucket_public_access_block" "medical_data" {
  bucket                  = aws_s3_bucket.medical_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "medical_data" {
  bucket = aws_s3_bucket.medical_data.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "medical_data" {
  bucket        = aws_s3_bucket.medical_data.id
  target_bucket = var.log_bucket_id
  target_prefix = "s3-access-logs/medical-data/"
}

resource "aws_s3_bucket_policy" "medical_data_tls" {
  bucket = aws_s3_bucket.medical_data.id
  policy = data.aws_iam_policy_document.enforce_tls_primary.json
}

data "aws_iam_policy_document" "enforce_tls_primary" {
  statement {
    sid       = "EnforceTLS"
    effect    = "Deny"
    principals {
      type = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.medical_data.arn, "${aws_s3_bucket.medical_data.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "medical_data" {
  bucket              = aws_s3_bucket.medical_data.id
  object_lock_enabled = "Enabled"
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 7 * 365
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "medical_data" {
  bucket = aws_s3_bucket.medical_data.id
  rule {
    id     = "archive-old-data"
    status = "Enabled"
    filter {
      prefix = ""
    }
    transition {
      days          = var.lifecycle_intelligent_tiering_days
      storage_class = "INTELLIGENT_TIERING"
    }
    transition {
      days          = var.lifecycle_glacier_days
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_metric" "medical_data" {
  bucket = aws_s3_bucket.medical_data.id
  name   = "EntireBucket"
}

# --- REPLICATION BUCKET (Secondary Region) ---

resource "aws_s3_bucket" "replication_dest" {
  provider      = aws.secondary
  bucket        = "${var.env}-platform-medical-data-dr"
  force_destroy = false

  tags = merge(var.common_tags, {
    Name = "DR-Backup-Medical-Data"
  })
}

resource "aws_s3_bucket_versioning" "replication_dest" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.replication_dest.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "replication_dest" {
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.replication_dest.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replication_dest" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.replication_dest.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn_secondary
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# --- REPLICATION CONFIGURATION & IAM ---

resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.medical_data]
  role       = aws_iam_role.replication.arn
  bucket     = aws_s3_bucket.medical_data.id

  rule {
    id     = "FullReplication"
    status = "Enabled"
    source_selection_criteria {
      sse_kms_encrypted_objects { status = "Enabled" }
    }
    destination {
      bucket        = aws_s3_bucket.replication_dest.arn
      storage_class = "STANDARD_IA"
      encryption_configuration {
        replica_kms_key_id = var.kms_key_arn_secondary
      }
    }
  }
}

resource "aws_iam_role" "replication" {
  name = "${var.env}-s3-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "replication" {
  name = "s3-replication-policy"
  role = aws_iam_role.replication.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [aws_s3_bucket.medical_data.arn]
      },
      {
        Action = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Effect = "Allow"
        Resource = ["${aws_s3_bucket.medical_data.arn}/*"]
      },
      {
        Action = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Effect = "Allow"
        Resource = ["${aws_s3_bucket.replication_dest.arn}/*"]
      },
      {
        Action = ["kms:Decrypt"]
        Effect = "Allow"
        Condition = {
          StringLike = { "kms:ViaService" = "s3.${data.aws_region.current.name}.amazonaws.com" }
        }
        Resource = [var.kms_key_arn]
      },
      {
        Action = ["kms:Encrypt"]
        Effect = "Allow"
        Resource = [var.kms_key_arn_secondary]
      }
    ]
  })
}

# MONITORING: CloudWatch Alarms for Replication
resource "aws_cloudwatch_metric_alarm" "replication_failed" {
  alarm_name          = "${var.env}-s3-replication-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReplicationFailedOperations"
  namespace           = "AWS/S3"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This alarm fires if any S3 replication operations fail for the medical data bucket."
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = aws_s3_bucket.medical_data.id
    RuleId     = "FullReplication"
  }
}

resource "aws_cloudwatch_metric_alarm" "replication_latency" {
  alarm_name          = "${var.env}-s3-replication-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = "900"
  statistic           = "Average"
  threshold           = "300000"
  alarm_description   = "Replication latency is higher than 5 minutes for medical data."

  dimensions = {
    BucketName = aws_s3_bucket.medical_data.id
    RuleId     = "FullReplication"
  }
}

data "aws_region" "current" {}
# --- VELERO BACKUP BUCKET ---

resource "aws_s3_bucket" "velero_backups" {
  bucket              = "${var.env}-platform-velero-backups"
  force_destroy       = false
  object_lock_enabled = true

  tags = merge(var.common_tags, {
    Name      = "${var.env}-platform-velero-backups"
    Purpose   = "Backups"
  })
}

resource "aws_s3_bucket_versioning" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "velero_backups" {
  bucket                  = aws_s3_bucket.velero_backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    filter {
      prefix = ""
    }
    expiration {
      days = 90
    }
  }
}
