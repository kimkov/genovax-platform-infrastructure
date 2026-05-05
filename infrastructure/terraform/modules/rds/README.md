### AWS RDS (PostgreSQL) Module

This module provides a production-ready, HIPAA-compliant implementation of **Amazon RDS for PostgreSQL**. 
It is designed to host the Platform platform's relational data with a strong focus on security, high availability, and performance.

### Features

*   **Security & Compliance**:
    *   **Encryption at Rest**: All data is encrypted at rest using a customer-managed AWS KMS key.
    *   **Encryption in Transit**: SSL is enforced via a custom parameter group (`rds.force_ssl = 1`).
    *   **HIPAA Ready**: Configured with 35-day backup retention and mandatory encryption to meet compliance requirements.
    *   **Private Access**: The database is deployed in private subnets and is not publicly accessible.
    *   **IAM Authentication**: Supports IAM database authentication for centralized identity management.
*   **High Availability & Scalability**:
    *   **Multi-AZ Deployment**: The primary instance is configured for Multi-AZ to ensure automatic failover.
    *   **Read Replicas**: Automatically provisions 2 read replicas to offload read traffic and increase availability.
    *   **Storage Autoscaling**: Dynamically scales storage up to 5000 GB based on workload needs.
*   **Performance & Monitoring**:
    *   **GP3 Storage**: Uses high-performance GP3 storage with configurable throughput and IOPS.
    *   **Performance Insights**: Enabled with a 7-day retention period for deep analysis of a database load.
    *   **Enhanced Monitoring**: Detailed metrics sent to CloudWatch at 60-second intervals.
    *   **CloudWatch Logs**: Automatically exports PostgreSQL and Upgrade logs for auditing.

### Usage Example

```hcl
module "rds" {
  source = "../../modules/rds"

  env          = "prod"
  vpc_id       = "vpc-0123456789abcdef0"
  subnet_ids   = ["subnet-abc12345", "subnet-def67890", "subnet-ghi90123"]
  kms_key_arn  = "arn:aws:kms:region:000000000000:key/your-key-id"
  
  db_name      = "platform_main"
  db_username  = "dbadmin"
  db_password  = var.rds_master_password # Marked as sensitive
  
  allowed_security_groups = [module.eks.node_security_group_id]
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `>= 5.0`   |

### Providers

| Name   | Version  |
|:-------|:---------|
| `aws`  | `>= 5.0` |

### Resources

| Name                            | Type     |
|:--------------------------------|:---------|
| `aws_db_instance.primary`       | resource |
| `aws_db_instance.replica`       | resource |
| `aws_db_parameter_group.rds_pg` | resource |
| `aws_db_subnet_group.rds`       | resource |
| `aws_security_group.rds`        | resource |

### Inputs

| Name                               | Description                                             | Type           | Default          | Required   |
|:-----------------------------------|:--------------------------------------------------------|:---------------|:-----------------|:-----------|
| **`env`**                          | The deployment environment name (e.g., `prod`, `dev`)   | `string`       | n/a              | **yes**    |
| **`vpc_id`**                       | ID of the VPC where the RDS instance will be deployed   | `string`       | n/a              | **yes**    |
| **`subnet_ids`**                   | List of private subnet IDs for the RDS subnet group     | `list(string)` | n/a              | **yes**    |
| **`allowed_security_groups`**      | Security Group IDs (e.g., EKS nodes) allowed to connect | `list(string)` | n/a              | **yes**    |
| **`db_name`**                      | The name of the default database to create              | `string`       | n/a              | **yes**    |
| **`db_username`**                  | Master username for the database administrator          | `string`       | n/a              | **yes**    |
| **`db_password`**                  | Master password for the database administrator          | `string`       | n/a              | **yes**    |
| **`kms_key_arn`**                  | ARN of the KMS key for storage encryption               | `string`       | n/a              | **yes**    |
| **`engine_version`**               | Database engine version (PostgreSQL)                    | `string`       | `"18.1"`         | no         |
| **`instance_class`**               | Compute and memory capacity (e.g., `db.r6g.large`)      | `string`       | `"db.r6g.large"` | no         |
| **`allocated_storage`**            | Initial storage allocation in gigabytes                 | `number`       | `500`            | no         |
| **`max_allocated_storage`**        | Upper limit for storage autoscaling                     | `number`       | `5000`           | no         |
| **`multi_az`**                     | Enable Multi-AZ for failover support                    | `bool`         | `true`           | no         |
| **`backup_retention_period`**      | Days to retain backups (HIPAA recommended: 35)          | `number`       | `35`             | no         |
| **`performance_insights_enabled`** | Enable Performance Insights                             | `bool`         | `true`           | no         |
| **`monitoring_interval`**          | Interval for Enhanced Monitoring metrics (seconds)      | `number`       | `60`             | no         |

### Outputs

| Name                          | Description                                          |
|:------------------------------|:-----------------------------------------------------|
| **`db_instance_endpoint`**    | The connection endpoint for the primary RDS instance |
| **`db_instance_identifier`**  | The ID of the primary RDS instance                   |
| **`db_instance_arn`**         | The ARN of the primary RDS instance                  |
| **`db_instance_resource_id`** | The resource ID of the primary RDS instance          |

### Implementation Details

1.  **High Availability**: The module deploys a primary instance in a Multi-AZ configuration and creates two read-only replicas across different availability zones to ensure data redundancy and read scalability.
2.  **Compliance**: By default, it forces SSL connections and retains backups for 35 days, aligning with HIPAA requirements for data integrity and recovery.
3.  **Network Security**: The database is restricted to private subnets. Ingress is strictly limited to traffic from the `allowed_security_groups` on port 5432 (PostgreSQL).
4.  **Monitoring**: CloudWatch log exports are enabled for `postgresql` and `upgrade` logs, providing an audit trail and easier troubleshooting.
5.  **Data Protection**: Deletion protection is enabled by default, and `skip_final_snapshot` is set to `false` for production environments to prevent data loss during teardown.