Status: Accepted
Context:
Requires a unified Single Sign-On (SSO) mechanism for employees and secure service-to-resource access.

Decision:
    AWS IAM Identity Center (SSO): Use as the primary mechanism for human identity management, integrated with external IdP (Office 365) via SAML.
    EKS IRSA (IAM Roles for Service Accounts): Assign IAM roles directly to pods via Service Accounts, avoiding the use of broad Node IAM roles.

Consequences:
    (+) Implementation of the Principle of Least Privilege.
    (+) Enhanced employee account security via MFA.