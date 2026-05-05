### AWS WAFv2 Module

This module provides a robust and secure AWS WAFv2 Web ACL configuration designed to protect regional resources like Application Load Balancers (ALB). 
It includes a set of managed rules to defend against common web exploits, rate limiting for DDoS protection, and a highly secure, HIPAA-compliant S3 logging infrastructure.

### Features

*   **Managed Threat Protection**:
    *   **OWASP Top 10**: Implements `AWSManagedRulesCommonRuleSet` to mitigate common vulnerabilities like path traversal and remote file inclusion.
    *   **SQL Injection Protection**: Includes `AWSManagedRulesSQLiRuleSet` to detect and block SQL injection attempts.
    *   **IP Reputation**: Blocks traffic from known malicious actors and bots using the `AWSManagedRulesAmazonIpReputationList`.
    *   **Known Bad Inputs**: Detects and blocks requests containing malicious patterns via `AWSManagedRulesKnownBadInputsRuleSet`.
*   **DDoS & Brute-force Mitigation**:
    *   **Rate Limiting**: Automatically blocks IP addresses that exceed 2,000 requests within a 5-minute window.
*   **Compliant Logging Architecture**:
    *   **Secure S3 Storage**: Dedicated bucket for WAF logs with strict security controls.
    *   **Encryption**: Logs are encrypted at rest using SSE-KMS with a customer-managed key.
    *   **HIPAA Compliance (Object Lock)**: Configured with S3 Object Lock in `COMPLIANCE` mode with a **365-day retention period**, ensuring audit logs are immutable and cannot be deleted.
    *   **Data Durability**: Bucket versioning is enabled to track changes and prevent accidental data loss.
    *   **Public Access Prevention**: Comprehensive public access block settings to ensure log privacy.
*   **Observability**:
    *   **CloudWatch Metrics**: Detailed metrics enabled for every rule and the Web ACL for monitoring and alerting.
    *   **Sampled Requests**: Enabled to allow for detailed analysis of matched traffic patterns.

### Usage Example

```hcl
module "waf" {
  source = "../../modules/waf"

  env         = "prod"
  kms_key_arn = "arn:aws:kms:region:000000000000:key/your-custom-s3-key"

  common_tags = {
    Project     = "Platform"
    Compliance  = "HIPAA"
    Environment = "Production"
  }
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `>= 5.0`   |

### Providers

| Name   | Version   | Description          |
|:-------|:----------|:---------------------|
| `aws`  | `>= 5.0`  | Primary AWS provider |

### Resources

| Name                                                          | Type     |
|:--------------------------------------------------------------|:---------|
| `aws_s3_bucket.waf_logs`                                      | resource |
| `aws_s3_bucket_public_access_block.waf_logs`                  | resource |
| `aws_s3_bucket_server_side_encryption_configuration.waf_logs` | resource |
| `aws_s3_bucket_versioning.waf_logs`                           | resource |
| `aws_s3_bucket_object_lock_configuration.waf_logs`            | resource |
| `aws_s3_bucket_policy.waf_logs_policy`                        | resource |
| `aws_wafv2_web_acl.main`                                      | resource |
| `aws_wafv2_web_acl_logging_configuration.main`                | resource |

### Inputs

| Name              | Description                                       | Type          | Default   | Required   |
|:------------------|:--------------------------------------------------|:--------------|:----------|:-----------|
| **`env`**         | Deployment environment name (e.g., `prod`, `dev`) | `string`      | n/a       | **yes**    |
| **`kms_key_arn`** | KMS Key ARN used for encrypting S3 log bucket     | `string`      | n/a       | **yes**    |
| **`common_tags`** | A map of tags to assign to all resources          | `map(string)` | `{}`      | no         |

### Outputs

| Name              | Description                                                                 |
|:------------------|:----------------------------------------------------------------------------|
| **`web_acl_arn`** | The ARN of the WAF Web ACL (to be associated with an ALB or other resource) |

### Implementation Details

1.  **Immutability**: The WAF logs are protected by a 365-day `COMPLIANCE` mode Object Lock. This is a critical control for HIPAA compliance, ensuring that security logs are preserved for the required audit duration and cannot be tampered with by any user, including the root account.
2.  **S3 Bucket Policy**: The module automatically attaches a bucket policy that grants the AWS Log Delivery service (`delivery.logs.amazonaws.com`) permission to write logs to the bucket.
3.  **Scope**: The Web ACL is defined with a `REGIONAL` scope. To use it with CloudFront, the module would need to be modified to use the `CLOUDFRONT` scope and be deployed in the `us-east-1` region.
4.  **Rule Ordering**:
    *   **Priority 1**: Rate Limiting (High-frequency attack mitigation).
    *   **Priority 5-20**: AWS Managed Rules (Known threat mitigation).
5.  **Logging Filter**: The logging configuration is set to `KEEP` all requests by default, ensuring a full audit trail for security analysis.