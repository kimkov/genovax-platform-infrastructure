Status: Accepted
Context:
Requires a unified Single Sign-On (SSO) mechanism for employees and secure service-to-resource access.

Decision:
    AWS Cognito: Use User Pools with mandatory "MFA" and federation via SAML (Office 365).
    EKS IRSA (IAM Roles for Service Accounts): Assign IAM roles directly to pods via Service Accounts, avoiding the use of broad Node IAM roles.

Consequences:
    (+) Implementation of the Principle of Least Privilege.
    (+) Enhanced employee account security via MFA.