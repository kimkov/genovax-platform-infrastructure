# Threat Model: GenovaX Platform

This document outlines the high-level threat model for the GenovaX infrastructure. As a medical technology platform handling ePHI (Electronic Protected Health Information), we prioritize data confidentiality, integrity, and availability.

## 1. Methodology
We use a simplified STRIDE-based approach to identify and mitigate risks at the infrastructure level.

## 2. Key Threat Scenarios & Mitigations

| Threat | Category | Mitigation in Code | Evidence (File Path) |
| :--- | :--- | :--- | :--- |
| **Unauthorized Access to PII/PHI** | Information Disclosure | Mandatory encryption at rest (KMS) and in transit (TLS 1.3). Private subnets only. | `infrastructure/terraform/modules/kms`, `infrastructure/terraform/modules/vpc` |
| **Data Ransomware / Accidental Deletion** | Tampering / DoS | S3 Object Lock (Compliance Mode) and AWS Backup with Vault Lock enabled. | `infrastructure/terraform/global/audit.tf`, `infrastructure/terraform/modules/aws_backup` |
| **Privilege Escalation via Service Account** | Elevation of Privilege | IAM Roles for Service Accounts (IRSA) with Least Privilege principle. | `infrastructure/terraform/modules/iam_roles_irsa` |
| **Exfiltration via Public Endpoints** | Information Disclosure | WAFv2 with managed rules and strict EKS NetworkPolicies (deny-all default). | `infrastructure/terraform/modules/waf`, `infrastructure/k8s/manifests/network-policies.yaml` |

## 3. Trust Boundaries
1.  **Public Boundary:** AWS CloudFront / WAF to ALB.
2.  **Network Boundary:** ALB to EKS Private Subnets.
3.  **Data Boundary:** EKS Pods to RDS/S3 via VPC Endpoints.

## 4. Remediation Strategy
All identified infrastructure vulnerabilities are tracked via automated scans (`Checkov`, `TFLint`) and addressed in CI/CD before deployment to production.
