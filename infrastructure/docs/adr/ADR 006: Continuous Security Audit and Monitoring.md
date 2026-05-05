Status: Accepted
Context:
Requires rapid response to security incidents and maintaining detailed audit logs.

decision:
    CloudTrail: Log all API calls, stored in S3 with Object Lock (365-day retention).
    GuardDuty & Security Hub: Automated threat detection and continuous compliance monitoring against AWS security best practices.
    CloudWatch Alarms: Real-time SNS alerts for unauthorized access attempts or network configuration changes.

Consequences:
    (+) Full transparency of all user actions within the system.
    (+) Automated compliance reporting for audits.