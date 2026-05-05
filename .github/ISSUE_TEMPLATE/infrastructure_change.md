---
name: "🏗 Infrastructure Change"
about: "Request changes to cloud resources or CI/CD pipelines"
title: "[INFRA] "
labels: ["infrastructure", "devops"]
assignees: ""
---

## 🏗 Infrastructure Change Request

## 🌍 Area of Change
- [ ] **AWS Core** (VPC, DNS, Load Balancers, WAF)
- [ ] **Compute** (EKS, EC2, Fargate)
- [ ] **Storage/Database** (RDS, S3, ElastiCache, DynamoDB)
- [ ] **Security/Identity** (IAM Roles, KMS, Secrets Manager)
- [ ] **CI/CD & Automation** (GitHub Actions, Terraform Cloud)
- [ ] **Kubernetes** (Helm Charts, Ingress, RBAC)

## 📖 Description & Rationale
<!-- 
  Provide a detailed description of the proposed change. 
  What is the technical justification? What problem does it solve?
-->

## 🛡 Security & Compliance (HIPAA)
<!-- 
  How does this change impact our security and compliance posture?
  - Does it introduce new IAM permissions? (The Least privilege principle)
  - Does it affect encryption at rest or in transit?
  - Does it change network isolation (Security Groups/NACLs)?
  - Is the audit trail preserved for HIPAA compliance?
-->

## 💰 Cost Analysis (Infracost)
<!-- 
  What is the estimated impact on the monthly AWS bill?
  Mention if an Infracost check is required or has been performed.
-->

## 🔄 Deployment & Rollback Strategy
<!-- 
  - **Environment**: (e.g., Apply to Dev first, then Staging, then Prod)
  - **Downtime**: Is any service interruption expected?
  - **Rollback**: How do we revert this change if things go wrong? (e.g., `terraform destroy`, state recovery, etc.)
-->

## 🔗 Dependencies & Impact
<!-- 
  - Does this depend on other PRs or Infrastructure changes?
  - Which services or teams will be impacted by this change?
-->

## ✅ Compliance & Privacy Check
- [ ] I confirm that this request **does not** contain any PII (Personally Identifiable Information) or PHI (Protected Health Information).
- [ ] I have verified that this change adheres to the [Security Policy](SECURITY.md).

## 📝 Additional Context
<!-- Add any diagrams (Mermaid), screenshots, or links to technical documentation. -->
