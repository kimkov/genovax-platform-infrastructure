## 📝 Description
<!-- Provide a brief summary of the changes and the rationale behind them. What problem does this PR solve? -->

## 🔗 Related Issues
<!-- Reference any related issues (e.g., Closes #123, Fixes GX-456) -->

## 🛠 Type of Change
- [ ] 🚀 New Feature
- [ ] 🐛 Bug Fix
- [ ] 🏗 Infrastructure Change (IaC)
- [ ] 🧹 Refactoring
- [ ] 📚 Documentation Update
- [ ] 🧪 Test Enhancement

## ✅ Self-Checklist

### General
- [ ] My code follows the [Contributing Guidelines](CONTRIBUTING.md).
- [ ] I have performed a self-review of my own code.
- [ ] I have added/updated tests that prove my fix is effective or that my feature works.
- [ ] New and existing unit tests pass locally with my changes.
- [ ] I have updated the documentation accordingly (README, internal docs, or KDoc/JSDoc).

### ⚖️ Security & Compliance (HIPAA)
- [ ] **Data Privacy**: I have verified that no PII (Personally Identifiable Information) is exposed in logs or error messages.
- [ ] **Encryption**: Changes involving data persistence ensure encryption at rest and in transit (AES-256, TLS 1.3).
- [ ] **Access Control**: Changes to IAM roles or Security Groups follow the principle of least privilege.
- [ ] **Audit**: Actions involving sensitive data are captured by the `compliance-audit` module.

### ☁️ Infrastructure & Cost
- [ ] **Infracost**: I have checked the cost impact of infrastructure changes (mandatory for `/infrastructure`).
- [ ] **Terraform**: `terraform fmt` has been run, and `checkov`/`tflint` scans pass locally.
- [ ] **Rollback**: I have a verified rollback plan for critical infrastructure or database migrations.

### 🧪 Quality Assurance
- [ ] **Coverage**: Business logic maintains at least 80% test coverage.
- [ ] **Performance**: I have considered the performance implications (e.g., DB query optimization, N+1 problems).

## 📸 Screenshots (if applicable)
<!-- Add screenshots or screen recordings to help the reviewer understand visual or UI changes. -->

---
*By submitting this PR, I confirm that my contribution is made under the terms of the project's license.*
