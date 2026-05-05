# Contributing to Platform Platform

First off, thank you for being part of the Platform mission! As a MedTech startup, we maintain high standards for code quality, security, and compliance.

This guide outlines the process and rules for contributing to our repository.

---

## 🏗 Development Workflow

We follow a structured branching strategy to ensure stability and auditability.

### Branching Strategy
- **`main`**: Production-ready code. No direct commits allowed.
- **`develop`**: Integration branch for current development.
- **`feature/GX-XXX-description`**: New features or improvements (use Jira/Issue ID).
- **`fix/GX-XXX-description`**: Bug fixes.
- **`hotfix/description`**: Urgent production fixes.

### How to contribute:
1. Create a new branch from `develop`.
2. Implement your changes.
3. Write/update tests (Unit, Integration, or E2E).
4. Ensure all CI checks pass locally.
5. Open a Pull Request (PR) against the `develop` branch.

---

## 📝 Commit Message Guidelines

We use **Conventional Commits** to automate changelogs and versioning.

**Format:** `<type>(<scope>): <description>`

**Types:**
- `feat`: A new feature.
- `fix`: A bug fix.
- `docs`: Documentation only changes.
- `style`: Changes that do not affect the meaning of the code (white-space, formatting).
- `refactor`: A code change that neither fixes a bug nor adds a feature.
- `test`: Adding missing tests or correcting existing tests.
- `chore`: Changes to the build process or auxiliary tools.

**Example:**
`feat(auth): add MFA support for clinician login`

---

## 🛠 Coding Standards

### Backend (Java/Spring Boot)
- Follow **Google Java Style Guide**.
- Use **Lombok** to reduce boilerplate, but avoid it in public API DTOs where clarity is preferred.
- All new API endpoints must be documented with **Swagger/OpenAPI** annotations.
- Maintain a minimum of **80% code coverage** for business logic.

### Frontend (TypeScript/Next.js)
- Use **Functional Components** and Hooks.
- Ensure strict typing; avoid `any`.
- Use `pnpm` for package management.

### Infrastructure (Terraform)
- Run `terraform fmt` before committing.
- Ensure no secrets are hardcoded (use AWS Secrets Manager or Vault).
- Pass `tflint` and `checkov` security scans.

---

## 🚀 Pull Request Process

To maintain high quality, every PR must meet these criteria:

1. **Title**: Follow conventional commit format.
2. **Description**:
    - What is the goal of this PR?
    - Which issue does it fix?
    - How was it tested?
3. **Reviewers**: At least one "Approve" from a lead developer is required.
4. **CI/CD**: All GitHub Actions (Build, Test, Security Scan) must be green.
5. **Squash & Merge**: We prefer squashing commits to keep the history clean.

---

## 🧪 Testing Requirements

- **Unit Tests**: Mandatory for all new logic.
- **Integration Tests**: Required for database interactions and API contracts.
- **Security**: For MedTech, ensure no PII (Personally Identifiable Information) is logged or exposed in error messages.

---

## 🛡 Security & Compliance

If you find a security vulnerability, **do not open a public Issue**. Instead, please report it privately to `security@example.com`.

Since we are HIPAA-compliant:
- Never commit real patient data.
- Use mocked data for all tests.
- Follow the principle of least privilege in IAM changes.

---

## 🆘 Need Help?

If you have questions or get stuck:
- Check the [Internal Documentation](./README.md#internal-documentation).
- Open a "Discussion" or ask in the `#dev-platform` Slack channel.
- Contact the maintainers at `dev-support@example.io`.