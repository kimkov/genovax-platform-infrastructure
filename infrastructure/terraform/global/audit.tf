# S3 Bucket for Auditing with Object Lock
resource "aws_s3_bucket" "audit_logs" {
  bucket = "example-global-audit-logs"
  object_lock_enabled = true
  tags = var.common_tags
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration { status = "Enabled" }
}

# Audit Bucket Policy: Encryption in Transit and CloudTrail Access
resource "aws_s3_bucket_policy" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  policy = data.aws_iam_policy_document.audit_logs_policy.json
}

data "aws_iam_policy_document" "audit_logs_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      identifiers = ["*"]
      type = "*"
    }
    actions = ["s3:*"]
    resources = [aws_s3_bucket.audit_logs.arn, "${aws_s3_bucket.audit_logs.arn}/*"]
    condition {
      test     = "Bool"
      values = ["false"]
      variable = "aws:SecureTransport"
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type = "Service"
    }
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      values = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
}

# Global CloudTrail (Multi-region)
resource "aws_cloudtrail" "global" {
  name                          = "example-global-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail.arn

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.cloudtrail_to_cloudwatch.arn

  event_selector {
    read_write_type = "ALL"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
}

# Separate KMS key for CloudTrail (Segregation of Duties)
resource "aws_kms_key" "cloudtrail" {
  description = "KMS key for CloudTrail logs encryption"
  deletion_window_in_days = 30
  enable_key_rotation = true
  policy = data.aws_iam_policy_document.cloudtrail_kms_policy.json
  tags = var.common_tags
}

resource "aws_kms_alias" "cloudtrail" {
  name = "alias/cloudtrail-key"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

data "aws_iam_policy_document" "cloudtrail_kms_policy" {
  statement {
    sid = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type = "AWS"
    }
    actions = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid = "Allow CloudTrail to encrypt logs"
    effect = "Allow"
    principals {
      identifiers = ["cloudtrail.amazonaws.com"]
      type = "Service"
    }
    actions = ["kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]
  }

  statement {
    sid = "Allow CloudWatch Logs to use the key"
    effect = "Allow"

    principals {
      identifiers = ["logs.amazonaws.com"]
      type = "Service"
    }
    actions = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
    resources = ["*"]
  }
}

# Configuring CloudWatch Logs for Real-Time Monitoring
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name = "/aws/cloudtrail/global-trail"
  retention_in_days = 90
  kms_key_id = aws_kms_key.cloudtrail.arn
  tags = var.common_tags
}

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name = "CloudTrailToCloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  name = "CloudTrailToCloudWatchPolicy"
  role   = aws_iam_role.cloudtrail_to_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

# Each object (log) placed in the audit bucket will be protected from deletion or modification for 365 days.
# The 'COMPLIANCE' mode is selected as the most stringent, prohibiting deletion even by a user with 'root' privileges.
resource "aws_s3_bucket_object_lock_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365
    }
  }
}

resource "aws_sns_topic" "global_security_alerts" {
  name = "example-global-security-alerts"
  tags = var.common_tags
}

resource "aws_sns_topic_subscription" "security_officer" {
  topic_arn = aws_sns_topic.global_security_alerts.arn
  protocol  = "email"
  endpoint  = var.security_notification_email
}