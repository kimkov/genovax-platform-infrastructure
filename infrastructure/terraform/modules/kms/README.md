### AWS KMS Module

This module provides a secure and centralized implementation of **AWS Key Management Service (KMS)** Customer Managed Keys (CMKs). 
It is designed to manage encryption at rest across various AWS services in a **HIPAA-compliant** manner, featuring automated key rotation, 
multi-region support for critical resources, and fine-grained resource-based policies.

### Features

*   **Dedicated Service Keys**: Separate KMS keys for RDS, EKS, S3, ECR, and Monitoring (CloudTrail/Config) to ensure isolation and limit the "blast radius."
*   **Security & Compliance**:
    *   **Automated Rotation**: Enables rotation for all keys to comply with security best practices.
    *   **Multi-Region Support**: RDS, EKS, and S3 keys are configured as multi-region keys, facilitating disaster recovery and cross-region replication of sensitive data.
    *   **Least Privilege Policies**: Pre-configured IAM policies grant permissions only to the specific AWS services and IAM roles that require them.
*   **Inter-Service Integration**:
    *   **RDS**: Explicitly allows the RDS service to use the key for database encryption.
    *   **S3**: Includes optional support for S3 cross-region replication roles.
    *   **ECR/EKS**: Implements conditional decryption rights for EKS worker nodes and authorized principals.
    *   **Monitoring**: Scoped access for CloudTrail and AWS Config to store logs securely.

### Usage Example

```hcl
module "kms" {
  source = "../../modules/kms"

  env = "prod"
  
  # Allow EKS nodes and specific roles to decrypt images and secrets
  ecr_allowed_read_principals = [
    "arn:aws:iam::000000000000:role/platform-prod-eks-node-role",
    "arn:aws:iam::000000000000:role/ci-cd-runner"
  ]
  
  # Required to enable the conditional policy for EKS
  eks_node_role_arn = "arn:aws:iam::000000000000:role/platform-prod-eks-node-role"

  # Role for cross-region S3 replication
  s3_replication_role_arn = "arn:aws:iam::000000000000:role/s3-replication-role"

  common_tags = {
    Environment = "prod"
    Project     = "Platform"
    Compliance  = "HIPAA"
  }
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `>= 5.0.0` |

### Providers

| Name   | Version    |
|:-------|:-----------|
| `aws`  | `>= 5.0.0` |

### Inputs

| Name                              | Description                                                      | Type           | Default  | Required   |
|:----------------------------------|:-----------------------------------------------------------------|:---------------|:---------|:-----------|
| **`env`**                         | The deployment environment name (e.g., `prod`, `dev`)            | `string`       | n/a      | **yes**    |
| **`common_tags`**                 | Common tags to apply to all KMS resources                        | `map(string)`  | `{}`     | no         |
| **`s3_replication_role_arn`**     | ARN of the IAM role used for S3 cross-region replication         | `string`       | `null`   | no         |
| **`eks_node_role_arn`**           | ARN of the EKS node role (enables decryption policy for EKS key) | `string`       | `null`   | no         |
| **`ecr_allowed_read_principals`** | List of ARNs allowed to decrypt ECR images and EKS secrets       | `list(string)` | `[]`     | no         |

### Outputs

| Name                     | Description                                         |
|:-------------------------|:----------------------------------------------------|
| **`rds_key_arn`**        | ARN of the KMS key for RDS encryption               |
| **`eks_key_arn`**        | ARN of the KMS key for EKS secrets encryption       |
| **`s3_key_arn`**         | ARN of the KMS key for S3 (medical data) encryption |
| **`monitoring_key_arn`** | ARN of the KMS key for CloudTrail and Config        |
| **`ecr_key_arn`**        | ARN of the KMS key for ECR image encryption         |

### Implementation Details

1.  **Administrative Access**: All keys include a policy statement granting the root account full access (`kms:*`) to ensure keys can always be managed by account administrators.
2.  **Rotation & Deletion**: Keys are configured with a 30-day deletion window and automatic rotation enabled.
3.  **Aliases**: Human-readable aliases are created for all keys (e.g., `alias/prod/rds`) for easier identification in the AWS Console and CLI.
4.  **Service Access**:
    *   **RDS**: `rds.amazonaws.com` is granted `Encrypt`, `Decrypt`, `ReEncrypt*`, `GenerateDataKey*`, and `DescribeKey`.
    *   **S3**: `s3.amazonaws.com` is granted `Decrypt` and `GenerateDataKey*`.
    *   **Monitoring**: `cloudtrail.amazonaws.com` and `config.amazonaws.com` are granted `GenerateDataKey*` and `Decrypt`.
