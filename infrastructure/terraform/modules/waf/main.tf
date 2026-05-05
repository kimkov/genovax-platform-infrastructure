# S3 Bucket for WAF logs
resource "aws_s3_bucket" "waf_logs" {
  bucket        = "aws-waf-logs-${var.env}-platform-audit"
  force_destroy = false
  object_lock_enabled = true

  tags = var.common_tags
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket                  = aws_s3_bucket.waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_object_lock_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365 # HIPAA Audit Log Retention Requirement
    }
  }
}

# Access policy for the WAF logging service
resource "aws_s3_bucket_policy" "waf_logs_policy" {
  bucket = aws_s3_bucket.waf_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowWAFLogDelivery"
      Effect = "Allow"
      Principal = { Service = "delivery.logs.amazonaws.com" }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.waf_logs.arn}/*"
      Condition = {
        StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
      }
    }]
  })
}

# Web ACL Configuration
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.env}-waf-acl"
  description = "Production WAF for ALB (HIPAA compliant)"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rate Limiting (Protection from DDoS and Brute-force)
  rule {
    name     = "RateLimit"
    priority = 1
    action { block {} }
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFRateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  # IP Reputation (Blocking bots and known crawlers)
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 5
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFIPReputationMetric"
      sampled_requests_enabled   = true
    }
  }

  # Common Rule Set (OWASP Top 10)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Known Bad Inputs (protection against malicious patterns)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 15
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFKnownBadInputsMetric"
      sampled_requests_enabled   = true
    }
  }

  # SQL Injection Protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 20
    override_action { none {} }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WAFSQLiMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env}-waf-main-metric"
    sampled_requests_enabled   = true
  }

  tags = var.common_tags
}

# Enabling Web ACL logging
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_s3_bucket.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn

  logging_filter {
    default_behavior = "KEEP"
  }
}

