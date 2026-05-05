# Local Environment Infrastructure

This module is designed to deploy the base infrastructure for the **Platform** project in a local environment. It utilizes [LocalStack](https://localstack.cloud/) to emulate AWS services, enabling development and testing without incurring cloud costs.

### Features
- **LocalStack Integration**: All resources are provisioned in a local container (default: `http://localhost:4566`).
- **Security**: Emulation of KMS and Secrets Manager for handling encrypted data and secrets.
- **Data Storage**: Configured S3 buckets for medical data (PHI) and system access logs.
- **Identity Management**: Local Cognito User Pool for testing authentication flows.
- **Messaging**: SQS queues and SNS topics for event-driven architecture testing.

---

### Prerequisites

To use this module, ensure you have the following installed:
1. **Terraform** version `1.5.0` or higher.
2. **LocalStack** (running via Docker).
3. **AWS CLI** (optional, for manual verification).

---

### Deployment Guide

1. **Start LocalStack**:
   ```bash
   docker-compose up -d  # or 'localstack start -d' if using the CLI
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Apply Configuration**:
   ```bash
   terraform apply -auto-approve
   ```

> **Note**: The state file `terraform.tfstate` is stored locally in this directory and should not be committed to version control.

---

### Technical Specification

#### Requirements

| Name      | Version   |
|:----------|:----------|
| terraform | >= 1.5.0  |
| aws       | ~> 5.0    |

#### Providers

| Name          | Version   | Description                                                  |
|:--------------|:----------|:-------------------------------------------------------------|
| aws           | ~> 5.0    | Primary provider configured for LocalStack endpoints         |
| aws.secondary | ~> 5.0    | Secondary provider (us-west-2) for S3 replication simulation |

#### Modules

| Name              | Source                | Description                               |
|:------------------|:----------------------|:------------------------------------------|
| `kms`             | ../../modules/kms     | Encryption key management                 |
| `s3_medical_data` | ../../modules/s3      | Storage for medical (PHI) and system data |
| `cognito`         | ../../modules/cognito | Identity provider for authentication      |

#### Resources

| Name                                    | Type     | Description                                |
|:----------------------------------------|:---------|:-------------------------------------------|
| `aws_s3_bucket.logs`                    | resource | S3 bucket for storing access logs          |
| `aws_secretsmanager_secret.db_password` | resource | Secret container for the database password |
| `aws_sqs_queue.audit_queue`             | resource | SQS queue for audit logging                |
| `aws_sns_topic.alerts`                  | resource | SNS topic for system alerts                |

#### Inputs

| Name          | Description                      | Type          | Default       |  Required  |
|:--------------|:---------------------------------|:--------------|:--------------|:----------:|
| `aws_region`  | AWS Region for local development | `string`      | `"us-east-1"` |     no     |
| `env`         | Environment identifier           | `string`      | `"local"`     |     no     |
| `common_tags` | Global resource tags             | `map(string)` | `{...}`       |     no     |

#### Outputs

| Name                   | Description                                      |
|:-----------------------|:-------------------------------------------------|
| `kms_s3_key_arn`       | ARN of the KMS key used for S3 encryption        |
| `phi_bucket_name`      | Name of the S3 bucket created for medical data   |
| `cognito_user_pool_id` | ID of the local Cognito User Pool                |
| `cognito_client_id`    | ID of the local Cognito User Pool Client         |
| `db_secret_arn`        | ARN of the Secrets Manager entry for DB password |

---

### Verification and Debugging

After deployment, you can verify the resources using the AWS CLI by specifying the local endpoint:

```bash
# List all local S3 buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# Retrieve the mock database password
aws --endpoint-url=http://localhost:4566 secretsmanager get-secret-value --secret-id local/rds/password

# Check SQS queues
aws --endpoint-url=http://localhost:4566 sqs list-queues