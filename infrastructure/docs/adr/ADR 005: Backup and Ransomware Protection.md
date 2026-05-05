Status: Accepted
Context:
Protection against data loss due to malicious attacks or human error is critical for healthcare systems.

Decision:
    AWS Backup with Vault Lock: Enable "Compliance Mode" to prevent backup deletion until the retention period expires.
    Continuous Backup: Enable Point-in-Time Recovery (PITR) for RDS and S3.
    Cross-Region Copy: Replicate critical backups to a secondary region for Disaster Recovery.

Consequences:
    (+) Data immutability (protection against deletion by hackers or admins).
    (+) Ability to restore data to any specific point in time.