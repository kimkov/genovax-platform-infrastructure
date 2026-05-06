terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}
# Data Sources
data "aws_region" "current" {}

# CloudWatch Log Group для CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/${var.env}-kms-monitoring"
  retention_in_days = 2557
  tags              = var.common_tags
}

# S3 Bucket for logs (Hardened & High-Compliance Ready)
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.env}-platform-cloudtrail-logs"
  force_destroy = false
  object_lock_enabled = true

  tags = var.common_tags
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

# Bucket policy to allow logging from ALB, CloudTrail, and Config
resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBLogDelivery"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/alb-logs/*"
      },
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid    = "AllowConfigWrite"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_object_lock_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365
    }
  }
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "${var.env}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = var.kms_key_arn

  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_role.arn
}

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.env}-cloudtrail-to-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.env}-cloudtrail-policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
    }]
  })
}

# AWS GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true
}

# AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.env}-aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.env}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.env}-config-channel"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id
  s3_kms_key_arn = var.kms_key_arn
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
}

# Security Hub
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "foundational" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# Alerts and Metrics
resource "aws_sns_topic" "security_alerts" {
  name = "${var.env}-security-alerts"
  tags = var.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

locals {
  security_metrics = {
    "IAMPolicyChanges"    = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=SetDefaultPolicyVersion)}"
    "NetworkACLChanges"   = "{($.eventName=CreateNetworkAcl)||($.eventName=CreateNetworkAclEntry)||($.eventName=DeleteNetworkAcl)||($.eventName=DeleteNetworkAclEntry)||($.eventName=ReplaceNetworkAclEntry)||($.eventName=ReplaceNetworkAclAssociation)}"
    "SecurityGroupChanges" = "{($.eventName=AuthorizeSecurityGroupIngress)||($.eventName=AuthorizeSecurityGroupEgress)||($.eventName=RevokeSecurityGroupIngress)||($.eventName=RevokeSecurityGroupEgress)||($.eventName=CreateSecurityGroup)||($.eventName=DeleteSecurityGroup)||($.eventName=ModifySecurityGroupRules)||($.eventName=UpdateSecurityGroupRuleDescriptionsIngress)||($.eventName=UpdateSecurityGroupRuleDescriptionsEgress)}"
    "RootUsage"           = "{$.userIdentity.type=\"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType !=\"AwsServiceEvent\"}"
    "UnauthorizedCalls"   = "{($.errorCode=\"*UnauthorizedOperation\") || ($.errorCode=\"AccessDenied*\")}"
    "KMSAccessDenied"     = "{ ($.eventSource = kms.amazonaws.com) && ($.eventName = Decrypt) && ($.errorCode = AccessDenied) }"
  }
}

resource "aws_cloudwatch_log_metric_filter" "security_filters" {
  for_each       = local.security_metrics
  name           = "${var.env}-${each.key}"
  pattern        = each.value
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name

  metric_transformation {
    name      = each.key
    namespace = "SecurityMonitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_alarms" {
  for_each            = local.security_metrics
  alarm_name          = "${var.env}-security-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = each.key
  namespace           = "SecurityMonitoring"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.env}-Application-Performance"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat: "Average" }],
            ["...", "...", "...", "...", { stat: "p95" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ALB Latency (Average vs p95)"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Application Errors (5XX)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", var.eks_cluster_name, { stat: "Average" }],
            [".", "pod_memory_utilization", ".", ".", { stat: "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EKS Pod Resources Utilization"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "eks_container_logs" {
  name = "/aws/eks/${var.eks_cluster_name}/containers"
  retention_in_days = 30
  kms_key_id = var.kms_key_arn

  tags = var.common_tags
}