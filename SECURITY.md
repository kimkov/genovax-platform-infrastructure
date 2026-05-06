# Security Policy

## Overview
GenovaX takes the security and privacy of patient data (PII/PHI) extremely seriously. As a MedTech platform, we are committed to maintaining the highest security standards for regulated environments. This policy outlines our process for reporting and handling security vulnerabilities.

## Supported Versions
We provide security updates for the following versions:

| Version   | Supported           |
|:----------|:--------------------|
| 1.2.x     | ✅ Yes (Current)     |
| 1.1.x     | ❌ No                |
| < 1.1     | ❌ No                |

## Reporting a Vulnerability
**Do not open a public GitHub issue for security vulnerabilities.** Please report vulnerabilities privately to ensure the safety of our users and data.

*   **Email:** [security@example.io](mailto:security@example.io)
*   **Encryption:** For sensitive reports, please use our [PGP Public Key](https://example.com/security/pgp-key.asc) (Fingerprint: `A1B2 C3D4 E5F6 G7H8 I9J0 K1L2 M3N4 O5P6 Q7R8 S9T0`).

**Your report should include:**
1.  A detailed description of the vulnerability.
2.  Clear steps to reproduce (POC).
3.  An assessment of the potential impact on PHI/PII or system integrity.
4.  (Optional) Suggested remediation.

## Our Commitment
We follow the principles of **Coordinated Vulnerability Disclosure (CVD)**.

*   **Acknowledgment:** We will acknowledge receipt of your report within **24 hours**.
*   **Triage & Severity:** Within **72 hours**, we will provide a preliminary assessment using the **CVSS v3.1** scale.
*   **Remediation Timelines:**
    *   **Critical (high compliance impact):** Fix within **7 days**.
    *   **High:** Fix within **14 days**.
    *   **Medium/Low:** Fix in the next scheduled release.
*   **Transparency:** Security advisories will be published via [GitHub Security Advisories](https://github.com/GenovaX/genovax-platform-infrastructure/security/advisories).

## Policy & Safe Harbor
### Scope
*   **In-Scope:**
    *   Core platform services and API Gateway.
    *   Infrastructure-as-Code (Terraform) in this repository.
    *   Patient data management modules.
*   **Out-of-Scope:**
    *   DDoS attacks.
    *   Social engineering or phishing.
    *   Third-party SaaS integrations (unless a misconfiguration in our code is the cause).
    *   Physical security of AWS data centers.

### Safe Harbor
We will not pursue legal action against researchers who:
*   Report findings in good faith.
*   Avoid privacy violations and do not access/modify actual patient data (use test accounts only).
*   Do not perform destructive actions (e.g., deleting logs or data).
*   Provide us with a reasonable amount of time to fix the issue before public disclosure.

## Security Practices
To maintain high compliance standards, we employ:
*   **Automated Scanning:** Every Pull Request is scanned with `Checkov` and `TFLint` for IaC security.
*   **Encryption:** AES-256 for data at rest and TLS 1.3 for data in transit.
*   **Audit Logging:** All access to PII is recorded in a tamper-proof audit trail.

---
*Last Updated: May 5, 2026*