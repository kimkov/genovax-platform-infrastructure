# Global Infrastructure (Global Layer)

This layer contains AWS resources that are common to the entire GenovaX organization and are not tied to specific environments or regions. These components provide the baseline security and Terraform state management.

## Core Components

### 1. State Management
Files: `s3-backend.tf`
- **S3 Bucket (`GenovaX-terraform-state-storage`):** Centralized storage for `.tfstate` files with versioning and KMS encryption enabled.
- **DynamoDB Table (`GenovaX-terraform-state-lock`):** Provides a state locking mechanism to prevent conflicts during concurrent Terraform runs.

### 2. Security and IAM
Files: `iam.tf`, `security-settings.tf`
- **Password Policy:** Strict requirements for password complexity and rotation (HIPAA compliance).
- **MFA Enforcement:** A policy that blocks resource access unless Multi-Factor Authentication (MFA) is enabled.
- **GitHub Actions OIDC:** Secure access configuration for CI/CD via OpenID Connect, eliminating the need for persistent access keys.
- **Audit Roles:** `SecurityAuditorRole` for resource inspection and compliance checks.
- **AWS Security Services:** Centralized GuardDuty, Security Hub, and AWS Config for continuous monitoring.

### 3. Budget Management
File: `budgets.tf`
- **Monthly Limit:** A spending limit is set (e.g., 1000 USD).
- **Notifications:** Alerts are configured to trigger at 80% of actual costs and 100% of forecasted costs.

### 4. Audit and Logging
Files: `audit.tf`
- **Audit Logs S3:** Secure storage for system logs with Object Lock (data immutability) enabled.
- **CloudTrail:** Multi-region trail with log file validation and KMS encryption.
- **Security Alerts:** SNS topics configured for immediate notification of Security Officer on critical events.
- **Route53:** Primary DNS zone configuration for the project (`route53.tf`).

---
**Deployment:** This layer must be deployed first, before any environment-specific resources are created.