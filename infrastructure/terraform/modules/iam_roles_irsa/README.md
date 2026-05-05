### IAM Roles for Service Accounts (IRSA) Module

This module provides a secure and automated implementation of **IAM Roles for Service Accounts (IRSA)** for Amazon EKS. 
It manages the creation of IAM roles and policies required by various Kubernetes controllers and applications, 
following the principle of least privilege by mapping AWS IAM roles to specific Kubernetes ServiceAccounts through the OIDC identity provider.

### Features

*   **Fine-Grained Access Control**: Leverages OIDC federation to grant specific AWS permissions to pods, eliminating the need for node-level IAM permissions.
*   **Controller Support**: Pre-configured roles for essential EKS add-ons:
    *   **AWS Load Balancer Controller**: Manages ALBs and NLBs for Ingress and Service resources.
    *   **Secrets Store CSI Driver**: Enables pods to retrieve secrets from AWS Secrets Manager and use KMS for decryption.
    *   **Velero**: Provides permissions for S3 backups and EBS snapshot management.
    *   **Cluster Autoscaler**: Manages Auto Scaling Groups (ASGs) based on cluster demand, scoped to the specific EKS cluster.
    *   **External DNS**: Automates Route53 record updates for Kubernetes services and ingresses.
    *   **Cert-Manager**: Facilitates DNS-01 challenges for automated TLS certificate issuance via Route53.
*   **Application Specific Roles**: Includes a dedicated role for **PHI Processor**, tailored for HIPAA-compliant workloads with restricted access to medical data in S3 and encryption keys in KMS.

### Usage Example

```hcl
module "iam_roles_irsa" {
  source = "../../modules/iam_roles_irsa"

  env                = "prod"
  cluster_name       = "platform-prod-cluster"
  oidc_provider      = module.eks.oidc_provider
  oidc_provider_arn  = module.eks.oidc_provider_arn
  kms_key_arn        = "arn:aws:kms:region:000000000000:key/your-kms-key-id"
  velero_bucket_name  = "platform-backups-prod"
  phi_s3_bucket_arn   = "arn:aws:s3:::platform-phi-data-prod"
  
  external_dns_zone_arns = [
    "arn:aws:route53:::hostedzone/Z1234567890ABC"
  ]

  common_tags = {
    Environment = "prod"
    Project     = "Platform"
  }
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `>= 5.0.0` |
| `http`      | `>= 3.0.0` |

### Providers

| Name   | Version    |
|:-------|:-----------|
| `aws`  | `>= 5.0.0` |
| `http` | `>= 3.0.0` |

### Inputs

| Name                         | Description                                                           | Type           | Default  | Required   |
|:-----------------------------|:----------------------------------------------------------------------|:---------------|:---------|:-----------|
| **`env`**                    | The deployment environment name (e.g., `prod`, `dev`)                 | `string`       | n/a      | **yes**    |
| **`cluster_name`**           | Name of the EKS cluster                                               | `string`       | n/a      | **yes**    |
| **`oidc_provider`**          | OIDC provider URL (without protocol)                                  | `string`       | n/a      | **yes**    |
| **`oidc_provider_arn`**      | OIDC provider ARN                                                     | `string`       | n/a      | **yes**    |
| **`kms_key_arn`**            | KMS key ARN for encryption (used by PHI processor and CSI driver)     | `string`       | n/a      | **yes**    |
| **`velero_bucket_name`**     | S3 bucket name for Velero backups                                     | `string`       | n/a      | **yes**    |
| **`phi_s3_bucket_arn`**      | ARN of the S3 bucket containing PHI data                              | `string`       | n/a      | **yes**    |
| **`external_dns_zone_arns`** | List of Route53 zone ARNs for External DNS and Cert-Manager to manage | `list(string)` | `["*"]`  | no         |
| **`common_tags`**            | Common tags to apply to all IAM resources                             | `map(string)`  | `{}`     | no         |

### Outputs

| Name                              | Description                               |
|:----------------------------------|:------------------------------------------|
| **`lbc_role_arn`**                | AWS Load Balancer Controller IAM Role ARN |
| **`secrets_store_csi_role_arn`**  | Secrets Store CSI Driver IAM Role ARN     |
| **`velero_role_arn`**             | Velero IAM Role ARN                       |
| **`cluster_autoscaler_role_arn`** | Cluster Autoscaler IAM Role ARN           |
| **`external_dns_role_arn`**       | External DNS IAM Role ARN                 |
| **`cert_manager_role_arn`**       | Cert-Manager IAM Role ARN                 |
| **`phi_processor_role_arn`**      | PHI Processor Application IAM Role ARN    |

### ServiceAccount Mapping

The roles created by this module expect the following ServiceAccounts in the EKS cluster:

| Component                    | Namespace      | ServiceAccount Name              |
|:-----------------------------|:---------------|:---------------------------------|
| AWS Load Balancer Controller | `kube-system`  | `aws-load-balancer-controller`   |
| Secrets Store CSI Driver     | `kube-system`  | `csi-secrets-store-provider-aws` |
| Velero                       | `velero`       | `velero`                         |
| Cluster Autoscaler           | `kube-system`  | `cluster-autoscaler`             |
| External DNS                 | `kube-system`  | `external-dns`                   |
| Cert-Manager                 | `cert-manager` | `cert-manager`                   |
| PHI Processor                | `phi-apps`     | `phi-processor`                  |
