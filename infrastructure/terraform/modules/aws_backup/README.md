### AWS Backup Terraform Module

This module provides a comprehensive, production-ready implementation of **AWS Backup**, 
designed to meet high-security standards and compliance requirements (such as HIPAA). It includes automated backup plans, 
immutability features (Vault Lock), monitoring, and disaster recovery capabilities.

### Features

*   **Multi-Tiered Backup Strategy**: Includes both Daily and Weekly backup rules with configurable lifecycles.
*   **Immutability (Vault Lock)**: Protects backup data against accidental or malicious deletion using `aws_backup_vault_lock_configuration`.
*   **Security & Compliance**:
    *   **Anti-Deletion Policy**: A vault-level access policy that denies `backup:DeleteRecoveryPoint` except for specified administrator roles.
    *   **Encryption**: Mandatory encryption for the Backup Vault and SNS notification topics using KMS.
    *   **Compliance Reporting**: Automated HIPAA-compliant backup reports delivered to an encrypted S3 bucket.
*   **Disaster Recovery (DR)**: Optional cross-region copy of backups to a secondary vault.
*   **Automated Restore Testing**: Built-in validation of recovery points to ensure data integrity and meeting RTO/RPO objectives.
*   **Monitoring & Logging**:
    *   SNS alerts for failed backup and restore jobs.
    *   CloudWatch Logs integration via EventBridge for all backup events.
*   **Resource Selection**: Dynamic selection of resources based on tags (defaulting to `Backup: true`).

### Usage

```hcl
module "aws_backup" {
  source = "./modules/aws_backup"

  env                = "prod"
  kms_key_arn        = "arn:aws:kms:region:000000000000:key/your-kms-key-id"
  sns_kms_key_arn    = "arn:aws:kms:region:000000000000:key/your-sns-kms-key-id"
  notification_email = "security-alerts@example.com"

  # Retention settings
  backup_retention_days   = 2555 # 7 years
  cold_storage_after_days = 30

  # Disaster Recovery
  dr_copy_enabled          = true
  dr_destination_vault_arn = "arn:aws:backup:region:000000000000:vault:dr-vault"

  # Break-glass access (Roles allowed to delete backups)
  admin_role_arns = [
    "arn:aws:iam::000000000000:role/OrganizationAdminRole"
  ]

  common_tags = {
    Project     = "GenovaX"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Requirements

| Name        | Version   |
|:------------|:----------|
| `terraform` | `>= 1.0`  |
| `aws`       | `6.17.0`  |

### Providers

| Name   | Version   |
|:-------|:----------|
| `aws`  | `6.17.0`  |

### Resources

| Name                                        | Type     |
|:--------------------------------------------|:---------|
| `aws_backup_vault.main`                     | resource |
| `aws_backup_vault_lock_configuration.main`  | resource |
| `aws_backup_vault_policy.main`              | resource |
| `aws_backup_plan.main`                      | resource |
| `aws_backup_selection.main`                 | resource |
| `aws_backup_report_plan.compliance_report`  | resource |
| `aws_backup_restore_testing_plan.main`      | resource |
| `aws_backup_restore_testing_selection.main` | resource |
| `aws_s3_bucket.reports`                     | resource |
| `aws_sns_topic.backup_notifications`        | resource |
| `aws_iam_role.backup`                       | resource |
| `aws_cloudwatch_log_group.backup`           | resource |

### Inputs

| Name                             | Description                                          | Type           | Default                                               | Required   |
|:---------------------------------|:-----------------------------------------------------|:---------------|:------------------------------------------------------|------------|
| `env`                            | Name of the deployment environment (prod, dev, etc.) | `string`       | n/a                                                   |  **yes**   |
| `kms_key_arn`                    | KMS key for Backup Vault encryption                  | `string`       | n/a                                                   |  **yes**   |
| `sns_kms_key_arn`                | Custom KMS key ARN for SNS topic encryption          | `string`       | n/a                                                   |  **yes**   |
| `notification_email`             | Email address for failure notifications              | `string`       | n/a                                                   |  **yes**   |
| `common_tags`                    | Common tags for all resources                        | `map(string)`  | `{}`                                                  |     no     |
| `backup_retention_days`          | Total days to keep backups                           | `number`       | `2555`                                                |     no     |
| `cold_storage_after_days`        | Days before moving to cold storage                   | `number`       | `30`                                                  |     no     |
| `backup_selection_tags`          | List of tags to select resources for backup          | `list(object)` | `[{type="STRINGEQUALS", key="Backup", value="true"}]` |     no     |
| `dr_copy_enabled`                | Enable cross-region backup copying                   | `bool`         | `true`                                                |     no     |
| `dr_destination_vault_arn`       | Destination Vault ARN for DR                         | `string`       | `null`                                                |     no     |
| `vault_lock_min_retention_days`  | Min retention for Vault Lock                         | `number`       | `7`                                                   |     no     |
| `vault_lock_max_retention_days`  | Max retention for Vault Lock                         | `number`       | `2555`                                                |     no     |
| `vault_lock_changeable_for_days` | Days Vault Lock remains changeable                   | `number`       | `3`                                                   |     no     |
| `admin_role_arns`                | Roles allowed to delete recovery points              | `list(string)` | `[]`                                                  |     no     |
| `enable_restore_testing`         | Enable automatic recovery check                      | `bool`         | `true`                                                |     no     |
| `restore_testing_schedule`       | Recovery Check Schedule (cron)                       | `string`       | `"cron(0 12 ? * 1 *)"`                                |     no     |
| `tested_resource_types`          | Resource types to test for recovery                  | `list(string)` | `["RDS", "EBS", "S3", "EC2"]`                         |     no     |
| `reports_bucket_name`            | S3 bucket name for reports                           | `string`       | `null`                                                |     no     |
| `log_retention_days`             | CloudWatch log retention period                      | `number`       | `90`                                                  |     no     |

### Outputs

| Name         | Description                  |
|:-------------|:-----------------------------|
| `vault_arn`  | The ARN of the backup vault  |
| `vault_name` | The name of the backup vault |
| `plan_id`    | The ID of the backup plan    |