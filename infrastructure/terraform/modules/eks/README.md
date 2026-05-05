### AWS EKS Module

This module provides a secure, production-ready implementation of **Amazon Elastic Kubernetes Service (EKS)**. It is designed to host the GenovaX platform's microservices with a strong focus on security, compliance, and scalability, utilizing both Managed Node Groups and Fargate for workload isolation.

### Features

*   **Security & Compliance**:
    *   **Private Endpoint**: The EKS cluster is configured with `cluster_endpoint_public_access = false`, ensuring the API server is only accessible within the VPC.
    *   **Secrets Encryption**: All Kubernetes secrets are encrypted at rest using a customer-managed AWS KMS key.
    *   **EBS Encryption**: Managed Node Groups are configured with encrypted EBS volumes using the specified KMS key.
    *   **IRSA (IAM Roles for Service Accounts)**: Full support for IRSA to provide fine-grained IAM permissions to Kubernetes pods.
    *   **HIPAA Ready**: Support for Fargate Profiles allows for strict isolation of workloads handling sensitive data (e.g., PHI).
*   **Networking**:
    *   **VPC CNI**: Uses Amazon VPC CNI for high-performance pod networking.
    *   **Network Policies**: Enabled by default to control traffic flow between pods.
    *   **IPv4/IPv6 Support**: Configurable IP family through the networking configuration.
*   **Compute Management**:
    *   **Managed Node Groups**: Automated provisioning and lifecycle management of EC2 nodes with customized instance types and storage.
    *   **Fargate Profiles**: Serverless compute for pods that require additional isolation or simplified management.
*   **Observability**:
    *   **Control Plane Logging**: Enables all essential log types (API, Audit, Authenticator, Controller Manager, Scheduler) for comprehensive monitoring and auditing.

### Usage Example

```hcl
module "eks" {
  source = "../../modules/eks"

  env          = "prod"
  cluster_name = "genovax-main-cluster"
  vpc_id       = "vpc-0123456789abcdef0"
  subnet_ids   = ["subnet-abc12345", "subnet-def67890"]
  kms_key_arn  = "arn:aws:kms:region:000000000000:key/your-key-id"

  node_groups = {
    main = {
      instance_types = ["m6i.large"]
      min_size     = 2
      max_size     = 10
      desired_size = 3
    }
  }

  fargate_profiles = {
    secure-workload = {
      selectors = [{ namespace = "secure-apps" }]
    }
  }
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `6.17.0`   |

### Providers

| Name  | Version   |
|:------|:----------|
| `aws` | `6.17.0`  |

### Resources

| Name                                                                                                        | Type   |
|:------------------------------------------------------------------------------------------------------------|:-------|
| [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) | module |

### Inputs

| Name                               | Description                                            | Type           | Default  | Required  |
|:-----------------------------------|:-------------------------------------------------------|:---------------|:---------|:----------|
| **`env`**                          | The deployment environment name (e.g., `prod`, `dev`)  | `string`       | n/a      | **yes**   |
| **`cluster_name`**                 | Name of the EKS cluster                                | `string`       | n/a      | **yes**   |
| **`vpc_id`**                       | ID of the VPC where the cluster will be deployed       | `string`       | n/a      | **yes**   |
| **`subnet_ids`**                   | List of private subnet IDs for nodes and control plane | `list(string)` | n/a      | **yes**   |
| **`kms_key_arn`**                  | ARN of the KMS key for secrets and EBS encryption      | `string`       | n/a      | **yes**   |
| **`kubernetes_networking_config`** | Kubernetes network settings (e.g., `ip_family`)        | `any`          | `{}`     | no        |
| **`node_groups`**                  | Configuration of managed node groups                   | `any`          | `{}`     | no        |
| **`fargate_profiles`**             | Configuration for Fargate profiles                     | `any`          | `{}`     | no        |

### Outputs

| Name                                     | Description                                                              |
|:-----------------------------------------|:-------------------------------------------------------------------------|
| **`cluster_endpoint`**                   | Endpoint for your Kubernetes API server                                  |
| **`node_security_group_id`**             | ID of the security group created for the nodes                           |
| **`cluster_name`**                       | The name of the EKS cluster                                              |
| **`cluster_certificate_authority_data`** | Base64 encoded certificate data required to communicate with the cluster |
| **`oidc_provider`**                      | The OpenID Connect identity provider (without protocol)                  |
| **`oidc_provider_arn`**                  | The ARN of the OIDC Provider                                             |
| **`node_iam_role_arn`**                  | IAM role ARN for EKS (Managed Node Group) nodes                          |

### Implementation Details

1.  **Version**: Deploys Kubernetes version **1.31**.
2.  **Private Networking**: The cluster is configured for internal access only; public endpoint access is disabled to enhance security.
3.  **Encrypted Storage**: All node volumes (EBS) are encrypted by default using the provided KMS key.
4.  **Logging**: Detailed logging is enabled and sent to CloudWatch for audit trails and performance analysis.
5.  **Add-ons**: Critical cluster components (`vpc-cni`, `coredns`, `kube-proxy`, and `aws-secrets-store-csi-driver`) are automatically managed and kept up-to-date.
6.  **Node Customization**: Managed node groups default to `m6i.large` instances on `gp3` volumes but can be overridden via the `node_groups` input.