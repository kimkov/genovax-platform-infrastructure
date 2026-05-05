### AWS S3 Storage Module

This module provides a production-ready, HIPAA-compliant implementation of **Amazon S3** storage for the Platform platform. 
It is specifically designed to handle sensitive medical data (ePHI) and backup files with a focus on security, durability, and regional redundancy.

### Features

*   **Security & Compliance**:
    *   **Encryption at Rest**: Mandatory encryption using Customer Managed Keys (CMK) via AWS KMS for all buckets.
    *   **Encryption in Transit**: Enforced TLS 1.2+ via bucket policies (`Deny` on non-HTTPS requests).
    *   **Object Lock (WORM)**: Enabled in `COMPLIANCE` mode with a 7-year retention period for medical data to meet regulatory requirements.
    *   **Public Access Block**: Strict blocking of all public ACLs and policies at the bucket level.
    *   **Access Logging**: Integrated with a centralized logging bucket for audit trails.
*   **Disaster Recovery & High Availability**:
    *   **Cross-Region Replication (CRR)**: Automatic asynchronous replication of medical data to a secondary AWS region for business continuity.
    *   **Versioning**: Enabled on all buckets to provide protection against accidental deletions and to support replication.
    *   **CloudWatch Alarms**: Built-in monitoring for replication failures and high latency (threshold set to 5 minutes).
*   **Lifecycle & Cost Management**:
    *   **Intelligent Tiering**: Automatically moves medical data to infrequent access tiers after 30 days (configurable).
    *   **Glacier Archiving**: Deep archiving for data older than 1 year.
    *   **Automated Expiration**: 90-day retention policy for Velero backups to manage storage costs.

### Usage Example

```hcl
module "s3" {
  source = "../../modules/s3"

  providers = {
    aws           = aws
    aws.secondary = Target region for replication
  }

  env          = "prod"
  kms_key_arn  = "arn:aws:kms:region:000000000000:key/primary-key-id"
  kms_key_arn_secondary = "arn:aws:kms:region:000000000000:key/secondary-key-id"
  log_bucket_id = "prod-centralized-logs-bucket"
  
  common_tags = {
    Project = "Platform"
    Owner   = "Infrastructure Team"
  }
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `>= 5.0`   |

### Providers

| Name            | Version   | Description                               |
|:----------------|:----------|:------------------------------------------|
| `aws`           | `>= 5.0`  | Primary region provider                   |
| `aws.secondary` | `>= 5.0`  | Secondary region provider for replication |

### Resources

| Name                                                   | Type     |
|:-------------------------------------------------------|:---------|
| `aws_s3_bucket.medical_data`                           | resource |
| `aws_s3_bucket.replication_dest`                       | resource |
| `aws_s3_bucket.velero_backups`                         | resource |
| `aws_s3_bucket_replication_configuration.replication`  | resource |
| `aws_s3_bucket_object_lock_configuration.medical_data` | resource |
| `aws_iam_role.replication`                             | resource |
| `aws_cloudwatch_metric_alarm.replication_failed`       | resource |

### Inputs

| Name                                     | Description                                                  | Type          | Default   | Required   |
|:-----------------------------------------|:-------------------------------------------------------------|:--------------|:----------|:-----------|
| **`env`**                                | The deployment environment name (e.g., `prod`, `dev`)        | `string`      | n/a       | **yes**    |
| **`kms_key_arn`**                        | ARN of the KMS key for S3 encryption in the primary region   | `string`      | n/a       | **yes**    |
| **`kms_key_arn_secondary`**              | ARN of the KMS key for S3 encryption in the secondary region | `string`      | n/a       | **yes**    |
| **`log_bucket_id`**                      | The ID of the S3 bucket where access logs will be stored     | `string`      | n/a       | **yes**    |
| **`common_tags`**                        | Common tags to be applied to all resources                   | `map(string)` | `{}`      | no         |
| **`lifecycle_intelligent_tiering_days`** | Days after which objects transition to Intelligent Tiering   | `number`      | `30`      | no         |
| **`lifecycle_glacier_days`**             | Days after which objects transition to Glacier               | `number`      | `365`     | no         |

### Outputs

| Name                         | Description                                                    |
|:-----------------------------|:---------------------------------------------------------------|
| **`bucket_id`**              | The name (ID) of the primary medical data bucket               |
| **`bucket_arn`**             | The ARN of the primary medical data bucket                     |
| **`replication_bucket_arn`** | The ARN of the replication (DR) bucket in the secondary region |
| **`replication_role_name`**  | The name of the IAM role used for S3 replication               |

### Implementation Details

1.  **Data Sovereignty & Compliance**: The `medical_data` bucket is tagged with `DataClass = ePHI`. The 7-year object lock ensures that records cannot be deleted or overwritten, fulfilling legal requirements for medical data retention.
2.  **Replication Monitoring**: Two CloudWatch alarms are provisioned to ensure the health of the Cross-Region Replication. One monitors failed operations (`ReplicationFailedOperations`), and the other monitors latency (`ReplicationLatency`) exceeding 5 minutes.
3.  **Velero Integration**: The module includes a dedicated `velero_backups` bucket with Object Lock enabled. It is configured with a lifecycle rule to expire backups after 90 days, ensuring a rolling window of recoverability while controlling costs.
4.  **Least Privilege**: The IAM role used for replication is scoped strictly to the primary and secondary buckets, with permissions limited to reading versions and replicating objects and tags.
