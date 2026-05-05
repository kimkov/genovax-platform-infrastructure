# Disaster Recovery (DR) Strategy: Platform Medical Data Platform

## 1. Introduction
This document outlines the Disaster Recovery (DR) strategy for the Platform platform. Given our handling of Protected Health Information (ePHI) and HIPAA compliance requirements, our primary focus is on data integrity and minimizing downtime during regional AWS outages.

## 2. Key Metrics (RPO and RTO)

| Service Level               | RPO (Recovery Point Objective)   | RTO (Recovery Time Objective)  | Description                                      |
|:----------------------------|:---------------------------------|:-------------------------------|:-------------------------------------------------|
| **Critical Data (ePHI/DB)** | **< 15 minutes**                 | **< 4 hours**                  | RDS Databases, medical images in S3.             |
| **Applications (EKS/API)**  | **< 1 hour**                     | **< 2 hours**                  | Kubernetes configs, Helm charts, Docker images.  |
| **Logs & Audit**            | **< 24 hours**                   | **< 8 hours**                  | CloudTrail, CloudWatch Logs, Compliance reports. |

*   **RPO (Recovery Point Objective):** The maximum acceptable amount of data loss measured in time.
*   **RTO (Recovery Time Objective):** The target time to restore service operations after a disaster.

## 3. Recovery Architecture (Cross-Region Strategy)

To ensure system resilience during a full regional failure, Platform uses a **Pilot Light / Warm Standby** strategy using a secondary AWS region.

### 3.1. Data Storage (Amazon S3)
*   **Mechanism:** Cross-Region Replication (CRR).
*   **Implementation:** All data in the `example-medical-data` bucket is asynchronously replicated to a secondary region.
*   **Security:** Replicas are protected using KMS (Cross-Region Keys) and S3 Object Lock (Compliance Mode) to prevent ransomware attacks, satisfying HIPAA data preservation requirements.

### 3.2. Databases (Amazon RDS / PostgreSQL)
*   **Mechanism:** AWS Backup + Cross-Region Copy.
*   **Implementation:** Daily DB snapshots and continuous transaction logs (WAL) are automatically copied to a secure Backup Vault in the DR region.
*   **High Availability:** Multi-AZ deployment is active in the primary region to protect against localized data center failures.

### 3.3. Infrastructure as Code (IaC)
*   **Mechanism:** Terraform.
*   **Implementation:** The entire infrastructure is defined in Terraform. In a disaster scenario, environment recreation is triggered by updating the `aws_region` variable and executing the CI/CD pipeline.

## 4. Disaster Recovery Activation Protocol (Runbook)

1.  **Detection:** CloudWatch Monitoring alerts on regional unavailability exceeding 10 minutes.
2.  **Decision:** CTO or DevOps Lead formally activates the DR protocol.
3.  **DB Restoration:** Restore the RDS instance from the latest cross-region recovery point.
4.  **App Deployment:** Execute Terraform to provision the EKS cluster and networking in the DR region.
5.  **DNS Failover:** Update Route53 records to point traffic to the new Application Load Balancer (ALB).
6.  **Verification:** Conduct integrity checks on ePHI data and API availability.

## 5. Compliance and HIPAA Standards
*   **Encryption:** All backups are encrypted using AES-256 (KMS) both at rest and in transit (TLS 1.2+).
*   **Auditability:** AWS Backup Audit Manager daily generates compliance reports for auditors.
*   **Testing:** Disaster Recovery Drills are conducted every 6 months to ensure readiness.