# Force encryption of all EBS disks in an account
resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

# Blocking public access to S3 at the account level
resource "aws_s3_account_public_access_block" "global" {
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# AWS GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true
}

# AWS Security Hub
resource "aws_securityhub_account" "main" {}

# AWS Config to track configuration changes
resource "aws_iam_role" "aws_config" {
  name = "AWSConfigRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "aws_config" {
  role       = aws_iam_role.aws_config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "global-config-recorder"
  role_arn = aws_iam_role.aws_config.arn
  recording_group {
    all_supported                = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "global-config-channel"
  s3_bucket_name = aws_s3_bucket.audit_logs.id
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# AWS IAM Access Analyzer to identify resources shared externally
resource "aws_accessanalyzer_analyzer" "main" {
  analyzer_name = "${var.project_name}-account-analyzer"
  type          = "ACCOUNT"
  tags          = var.common_tags
}