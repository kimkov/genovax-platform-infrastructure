# Contributing to GenovaX Platform

Thank you for your interest in GenovaX! As a medical technology platform, we maintain high standards for security, compliance, and code quality.

## 🛠 Infrastructure Workflow (IaC)

We use Terraform for infrastructure management. All changes must follow this workflow:

1.  **Branching:** Create a feature branch from `main` (e.g., `feat/add-msk-cluster`).
2.  **Local Validation:** Run the security suite before committing.
3.  **Pull Request:** Open a PR against `main`.
4.  **Security Scan:** Automated GitHub Actions will run Checkov and TFLint.
5.  **Review:** At least one Cloud Architect must approve the PR.
6.  **Apply:** Changes are applied via CI/CD after merge.

## 🛡 Security Checks

Before submitting a PR, ensure your code passes the local security scan:
```bash
./infrastructure/scripts/check-security.sh
```
This script runs:
*   **Checkov:** Static analysis for security misconfigurations.
*   **TFLint:** Linter for AWS provider-specific best practices.
*   **TruffleHog:** Scans for accidentally committed secrets.

## 🏷 Tagging Policy

All resources must be tagged using the following mandatory keys for billing and ownership tracking:
*   `Project`: `GenovaX`
*   `Environment`: `dev`, `prod`, or `global`
*   `Owner`: Team responsible for the resource (default: `Cloud-Architecture-Team`)
*   `ManagedBy`: `Terraform`

## 🤝 Code Style
*   Use `camelCase` for resource names in Terraform.
*   Always provide `description` for variables and outputs.
*   Maintain the modular structure in `infrastructure/terraform/modules`.