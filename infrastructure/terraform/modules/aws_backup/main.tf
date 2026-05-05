terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

# Main Storage (Vault)
resource "aws_backup_vault" "main" {
  name = "${var.env}-backup-vault"
  kms_key_arn = var.kms_key_arn
  tags = var.common_tags
}

# Security Enhancement: Vault Access Policy (Anti-deletion)
resource "aws_backup_vault_notifications" "main" {
  backup_vault_name = aws_backup_vault.main.name
  sns_topic_arn = aws_sns_topic.backup_notifications.arn
  backup_vault_events = ["BACKUP_JOB_FAILED", "RESTORE_JOB_FAILED"]
}

resource "aws_backup_vault_policy" "main" {
  backup_vault_name = aws_backup_vault.main.name

  policy            = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDeleteRecoveryPoint"
        Effect = "Deny"
        Principal = "*"
        Action    = "backup:DeleteRecoveryPoint"
        # Deletion is only allowed for admin roles (Break-glass)
        Condition = {
          StringNotLike = {
            "aws:PrincipalArn" = var.admin_role_arns
          }
        }
      }
    ]
  })
}

# Setting up immutability (Vault Lock)
resource "aws_backup_vault_lock_configuration" "main" {
  backup_vault_name = aws_backup_vault.main.name
  changeable_for_days = var.vault_lock_changeable_for_days
  max_retention_days = var.vault_lock_max_retention_days
  min_retention_days = var.vault_lock_min_retention_days
}

# Flexible plans: Daily and Weekly backups + DR + Tagging
resource "aws_backup_plan" "main" {
  name = "${var.env}-daily-backup-plan"

  # Daily backup
  rule {
    rule_name = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule = "cron(0 5 * * ? *)" # Every day at 05:00

    lifecycle {
      cold_storage_after = var.cold_storage_after_days
      delete_after = var.backup_retention_days
    }

    # Tagging restore points
    recovery_point_tags = merge(var.common_tags, {
      BackupPlan = "Daily"
      ManagedBy  = "Terraform"
    })

    # Disaster Recovery (Copy to another region)
    dynamic "copy_action" {
      for_each = var.dr_copy_enabled && var.dr_destination_vault_arn != null ? [1] : []
      content {
        destination_vault_arn = var.dr_destination_vault_arn
        lifecycle {
          cold_storage_after = var.cold_storage_after_days
          delete_after = var.backup_retention_days
        }
      }
    }
  }

  # Weekly backup (stored longer in warm storage)
  rule {
    rule_name         = "weekly-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule = "cron(0 5 ? * 1 *)" # Every Sunday

    lifecycle {
      cold_storage_after = 90 # Goes cold later than daily
      delete_after = var.backup_retention_days
    }

    recovery_point_tags = merge(var.common_tags, {
      BackupPlan = "Weekly"
    })
  }
  tags = var.common_tags
}

# Audit
resource "aws_backup_report_plan" "compliance_report" {
  name        = "${var.env}-hipaa-compliance-report"
  description = "HIPAA Backup Compliance Report"

  report_delivery_channel {
    s3_bucket_name = aws_s3_bucket.reports.id
    formats        = ["CSV", "JSON"]
  }

  report_setting {
    report_template = "COMPLIANCE_CONTROL_REPORT"
  }

  tags = var.common_tags
}

# Roles and Policies
resource "aws_iam_role" "backup" {
  name = "${var.env}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role = aws_iam_role.backup.name
}

resource "aws_iam_role_policy_attachment" "restore" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role = aws_iam_role.backup.name
}

resource "aws_backup_selection" "main" {
  iam_role_arn = aws_iam_role.backup.arn
  name = "${var.env}-backup-selection"
  plan_id = aws_backup_plan.main.id

  dynamic "selection_tag" {
    for_each = var.backup_selection_tags
    content {
      type = selection_tag.value.type
      key = selection_tag.value.key
      value = selection_tag.value.value
    }
  }
}

# Monitoring: SNS with a custom KMS key
resource "aws_sns_topic" "backup_notifications" {
  name = "${var.env}-backup-notifications"
  kms_master_key_id = var.sns_kms_key_arn
  tags = var.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.backup_notifications.arn
  protocol = "email"
  endpoint = var.notification_email
}

resource "aws_backup_vault_notifications" "main" {
  backup_vault_events = ["BACKUP_JOB_FAILED", "RESTORE_JOB_FAILED"]
  backup_vault_name = aws_backup_vault.main.name
  sns_topic_arn     = aws_sns_topic.backup_notifications.arn
}

# S3 Bucket for Reports
resource "aws_s3_bucket" "reports" {
  bucket = var.reports_bucket_name != null ? var.reports_bucket_name : "${var.env}-backup-reports-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
  tags          = var.common_tags
}

resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Restore Validation
resource "aws_backup_restore_testing_plan" "main" {
  count = var.enable_restore_testing ? 1 : 0
  name  = "${var.env}-restore-testing-plan"

  recovery_point_selection {
    algorithm      = "LATEST_WITHIN_WINDOW"
    include_vaults = [aws_backup_vault.main.arn]
    recovery_point_types = ["CONTINUOUS", "SNAPSHOT"]
    selection_window_days = 1
  }

  schedule_expression = var.restore_testing_schedule
  start_window_hours  = 8
}

resource "aws_backup_restore_testing_selection" "main" {
  for_each = var.enable_restore_testing ? toset(var.tested_resource_types) : []

  name  = "${var.env}-${lower(each.value)}-selection"
  restore_testing_plan_name = aws_backup_restore_testing_plan.main[0].name

  # Role for testing recovery (requires AWSBackupServiceRolePolicyForRestores policy)
  iam_role_arn = aws_iam_role.backup.arn

  protected_resource_type = each.value

  # Selecting resources by tags
  protected_resource_conditions {
    string_equals {
      key   = "aws:ResourceTag/Backup"
      value = "true"
    }
  }
}

# Logging in CloudWatch
resource "aws_cloudwatch_log_group" "backup" {
  name              = "/aws/backup/${var.env}-vault-events"
  retention_in_days = var.log_retention_days
  tags              = var.common_tags
}

# CloudWatch Event Rule (EventBridge) is used to export events.
resource "aws_cloudwatch_event_rule" "backup_events" {
  name        = "${var.env}-backup-events-rule"
  description = "Capture all AWS Backup events"

  event_pattern = jsonencode({
    source = ["aws.backup"]
  })
}

resource "aws_cloudwatch_event_target" "cloudwatch" {
  rule      = aws_cloudwatch_event_rule.backup_events.name
  target_id = "SendToCloudWatch"
  arn       = aws_cloudwatch_log_group.backup.arn
}

data "aws_caller_identity" "current" {}