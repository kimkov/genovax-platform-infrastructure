### AWS Monitoring & Security Module

This module implements a comprehensive security monitoring and auditing framework for AWS environments. 
It is designed to meet high-security standards (such as **HIPAA** and **SOC2**) by centralizing logs, enabling threat detection, 
and providing real-time alerts for critical security events.

### Features

*   **Audit Logging (AWS CloudTrail)**:
    *   Multi-region trail enabled for global visibility.
    *   Log file integrity validation to ensure non-repudiation.
    *   Encryption at rest using AWS KMS.
    *   Integration with both S3 (long-term storage) and CloudWatch Logs (real-time analysis).
*   **Hardened Storage**:
    *   Dedicated S3 bucket for logs with **Object Lock** in `COMPLIANCE` mode (1-year retention).
    *   Server-Side Encryption (SSE) and Public Access Block enabled.
    *   Bucket policies are configured for secure log delivery from ALB, CloudTrail, and AWS Config.
*   **Threat Detection (AWS GuardDuty)**:
    *   Continuous monitoring for malicious activity and unauthorized behavior.
*   **Compliance & Governance (AWS Config & Security Hub)**:
    *   **AWS Config**: Records resource configurations and evaluates them against security rules (e.g., checking for encrypted EBS volumes).
    *   **Security Hub**: Subscribes to AWS Foundational Security Best Practices.
*   **Real-time Security Alerts**:
    *   **CloudWatch Metric Filters**: Monitors logs for IAM policy changes, Network ACL/Security Group modifications, Root account usage, Unauthorized API calls, and KMS access denials.
    *   **SNS Notifications**: Sends immediate email alerts to security administrators when suspicious events are detected.

### Usage Example

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  env                = "prod"
  notification_email = "security-alerts@example.com"
  kms_key_arn        = module.kms.monitoring_key_arn

  common_tags = {
    Environment = "prod"
    Project     = "Platform"
    ManagedBy   = "Terraform"
  }
}
```

### Requirements

| Name        | Version     |
|:------------|:------------|
| `terraform` | `>= 1.5.0`  |
| `aws`       | `~> 6.17.0` |

### Providers

| Name  | Version     |
|:------|:------------|
| `aws` | `~> 6.17.0` |

### Inputs

| Name                     | Description                                                         | Type          | Default  | Required   |
|:-------------------------|:--------------------------------------------------------------------|:--------------|:---------|:-----------|
| **`env`**                | The deployment environment name (e.g., `prod`, `dev`)               | `string`      | n/a      | **yes**    |
| **`notification_email`** | Email address to receive security alerts and notifications          | `string`      | n/a      | **yes**    |
| **`kms_key_arn`**        | KMS Key ARN used for encrypting CloudTrail logs and Config delivery | `string`      | n/a      | **yes**    |
| **`common_tags`**        | A map of tags to assign to all resources in the module              | `map(string)` | `{}`     | no         |

### Outputs

| Name                             | Description                                                       |
|:---------------------------------|:------------------------------------------------------------------|
| **`cloudtrail_logs_bucket_arn`** | ARN of the S3 bucket used for infrastructure and audit logs       |
| **`cloudtrail_logs_bucket_id`**  | ID (name) of the S3 bucket used for infrastructure and audit logs |

### Implementation Details

1.  **Retention Strategy**: CloudWatch logs are retained for 2557 days (7 years) to satisfy long-term compliance requirements.
2.  **Immutability**: The S3 logging bucket uses WORM (Write Once, Read Many) technology via Object Lock to prevent accidental or malicious deletion of audit trails.
3.  **Monitored Security Events**:
    *   **IAMPolicyChanges**: Detection of any modifications to IAM policies or roles.
    *   **NetworkACLChanges / SecurityGroupChanges**: Monitoring changes to network perimeter security.
    *   **RootUsage**: Alerts whenever the AWS account Root user is used.
    *   **UnauthorizedCalls**: Tracks failed API attempts (Access Denied).
    *   **KMSAccessDenied**: Specific monitoring for unauthorized attempts to use encryption keys.
4.  **Security Hub Integration**: Automatically enables the "AWS Foundational Security Best Practices" standard to provide a continuous security score.