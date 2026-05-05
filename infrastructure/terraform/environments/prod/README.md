# Production Environment (Prod Environment)

This layer describes the target infrastructure for the GenovaX application in the production environment. The configuration focuses on high availability (Multi-AZ), security (HIPAA compliance), and scalability.

## Core Components

### 1. Compute and Orchestration
- **Amazon EKS:** A managed Kubernetes cluster for running microservices.
  - **Networking:** IPv6-native pod networking for high scalability.
  - **IAM Roles for Service Accounts (IRSA):** Granular access control for Kubernetes controllers (Fluent-bit, Load Balancer Controller).
- **Fargate Profiles:** Used for isolating critical data processing (PHI) within the `phi-apps` namespace to ensure maximum security.
- **EKS Addons:** Includes Fluent-bit for log collection and the AWS Load Balancer Controller for traffic management.
- **Namespaces:** Dedicated namespaces created for operational isolation (`phi-apps`, `velero`).

### 2. Databases (RDS)
- **PostgreSQL (RDS):** Deployed in a Multi-AZ configuration for high availability.
- **Security:** Network access is restricted to the EKS cluster only; credentials are managed securely via AWS Secrets Manager.
- **Pre-requisite:** The RDS password secret must be manually created in AWS Secrets Manager (`prod/rds/password`) before deployment.

### 3. Networking and Protection
- **Dual-Stack VPC:** Support for both IPv4 and IPv6 networking.
- **AWS WAF:** A web application firewall to protect public-facing endpoints from common web exploits.
- **VPC Endpoints:** Ensure private access to AWS services (S3, ECR, KMS) without traffic leaving the AWS private network.

### 4. Storage and Container Registry
- **ECR:** Dedicated repositories for `api-gateway`, `phi-processor`, and `auth-service`.
- **S3 Medical Data:** A specialized bucket for storing medical data with mandatory encryption and access logging.

### 5. Encryption and Backups
- **KMS:** Dedicated customer-managed keys for RDS, S3, EKS, and monitoring data.
- **AWS Backup:** Automated backup plans for RDS and S3 with notification alerts sent to the Security Officer.

## Workflow
1. Ensure the global layer (`global`) is successfully deployed.
2. **Pre-deployment:** Create the RDS secret in AWS Secrets Manager (`prod/rds/password`).
3. Initialize Terraform: `terraform init`.
4. Plan and review changes: `terraform plan`.
5. Apply the configuration: `terraform apply`.