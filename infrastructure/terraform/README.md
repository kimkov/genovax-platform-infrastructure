### Platform Infrastructure - Terraform

This repository contains the Infrastructure as Code (IaC) configuration for the **Platform** project. We use **Terraform** 
to manage AWS resources, ensuring scalability, security, and reproducibility across all environments.

### Project Architecture

The project follows a modular design to separate concerns and simplify maintenance:

*   **`environments/`**: Contains environment-specific configurations. Each environment invokes modules with relevant parameters.
    *   `local/`: Local development environment using **LocalStack**.
    *   `dev/`: Development and testing environment hosted in AWS.
    *   `prod/`: Production environment optimized for high availability and security.
*   **`modules/`**: Reusable modules for standard infrastructure components:
    *   **Networking**: `vpc`, `vpc_endpoints`, `alb`, `cloudfront`, `route53`.
    *   **Compute**: `eks` (Kubernetes), `iam_roles_irsa`.
    *   **Storage**: `s3`, `rds`, `elasticache`, `ecr`.
    *   **Security**: `kms`, `waf`, `cognito`, `macie`.
    *   **Monitoring**: `monitoring`, `aws_backup`.
*   **`global/`**: Resources shared across all environments or critical baseline elements:
    *   S3 Backend for state storage.
    *   Global IAM roles and policies.
    *   Organization-wide security settings.

### Prerequisites

Before you begin, ensure you have the following installed:

1.  **Terraform** (version `>= 1.5.0`).
2.  **AWS CLI** (configured with appropriate credentials).
3.  **LocalStack** (required only for the `local` environment).
4.  **kubectl** and **Helm** (for managing components within EKS).

### Quick Start

#### 1. Choose an Environment
Navigate to the directory of the target environment:
```bash
cd infrastructure/terraform/environments/dev
```

#### 2. Initialization
Download the required providers and modules:
```bash
terraform init
```

#### 3. Plan Changes
Review the execution plan to see the resources that will be created or modified:
```bash
terraform plan
```

#### 4. Apply Configuration
Deploy the infrastructure:
```bash
terraform apply
```

### Standards and Security

*   **Encryption**: All data at rest (S3, RDS, EBS, EKS) is encrypted using KMS keys managed through the `kms` module.
*   **Networking**: Implements a Dual-stack (IPv4/IPv6) configuration. Public exposure is minimized by using Private Subnets and VPC Endpoints.
*   **Access Control**: Kubernetes uses **IRSA** (IAM Roles for Service Accounts), ensuring pods operate with the principle of least privilege.
*   **Tagging**: Mandatory tags (`Environment`, `Project`, `Owner`) are enforced and automatically applied via `default_tags` in the provider configuration.

### State Management

Terraform state is stored remotely in an S3 bucket with state locking via DynamoDB to prevent concurrent modifications (configured in `global/s3-backend.tf`).

> **Important**: Never commit `.tfstate` files to the version control system.