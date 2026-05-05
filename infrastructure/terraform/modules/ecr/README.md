### AWS ECR Module

This module provides a secure and production-ready implementation of **Amazon Elastic Container Registry (ECR)**. 
It is designed to manage container image repositories with built-in security features, automated lifecycle management, 
and granular access control for the GenovaX ecosystem.

### Features

*   **Security & Compliance**:
    *   **KMS Encryption**: All images are encrypted at rest using a customer-managed AWS KMS key (SSE-KMS).
    *   **Enhanced Scanning**: Enables **Enhanced Continuous Scanning** (via Amazon Inspector) to automatically detect vulnerabilities in container images upon push and through continuous monitoring.
    *   **Tag Immutability**: Repositories are configured as `IMMUTABLE` to prevent existing image tags from being overwritten, ensuring deployment consistency.
*   **Lifecycle Management**:
    *   **Untagged Image Cleanup**: Automatically expires untagged images older than 7 days to keep the registry clean.
    *   **Retention Control**: Maintains only the most recent 50 images per repository to optimize storage costs.
*   **Access Management**:
    *   **Least Privilege Access**: Provides a simplified way to grant pull permissions to specific IAM principals (e.g., EKS Node Groups or CI/CD roles).

### Usage Example

```hcl
module "ecr" {
  source = "../../modules/ecr"

  env              = "prod"
  repository_names = ["example-api", "example-worker"]
  kms_key_arn      = "arn:aws:kms:region:000000000000:key/your-key-id"
  
  allowed_read_principals = [
    "arn:aws:iam::000000000000:role/eks-node-group-role"
  ]

  common_tags = {
    Project     = "GenovaX"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `6.17.0`   |

### Providers

| Name  | Version  |
|:------|:---------|
| `aws` | `6.17.0` |

### Resources

| Name                                                                                                                                                            | Type     |
|:----------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository)                                           | resource |
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy)                               | resource |
| [aws_ecr_repository_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy)                             | resource |
| [aws_ecr_registry_scanning_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_registry_scanning_configuration) | resource |

### Inputs

| Name                          | Description                                           | Type           | Default   | Required   |
|:------------------------------|:------------------------------------------------------|:---------------|:----------|:-----------|
| **`env`**                     | The deployment environment name (e.g., `prod`, `dev`) | `string`       | n/a       | **yes**    |
| **`repository_names`**        | List of names for the ECR repositories                | `list(string)` | n/a       | **yes**    |
| **`kms_key_arn`**             | ARN of the KMS key for image encryption               | `string`       | n/a       | **yes**    |
| **`common_tags`**             | Common tags for resources                             | `map(string)`  | n/a       | **yes**    |
| **`allowed_read_principals`** | List of ARNs allowed to pull images                   | `list(string)` | `[]`      | no         |

### Outputs

| Name                  | Description                             |
|:----------------------|:----------------------------------------|
| **`repository_urls`** | Map of repository names and their URLs. |
| **`repository_arns`** | Map of repository names and their ARNs. |

### Implementation Details

1.  **Immutability**: Image tags are immutable to prevent overwriting deployed versions.
2.  **Lifecycle Rules**: Automated cleanup for untagged images (7 days) and a 50-image limit per repository.
3.  **Scanning**: Continuous enhanced scanning is enabled for all repositories to ensure security compliance.
4.  **Access Control**: A repository policy is applied to each repository granting pull access to specified principals.