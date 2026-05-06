Status: Accepted
Context:
Requires database resilience and strict adherence to encryption requirements (Encryption at Rest/Transit).

Decision:
    RDS PostgreSQL 18.1 Multi-AZ: Automatic replication across Availability Zones.
    KMS CMK: Use Customer Managed Keys (CMK) for each resource type (RDS, S3, EKS).
    SSL Enforcement: Mandatory TLS for all database connections (`rds.force_ssl = 1`).

Consequences:
    (+) High compliance for data encryption.
    (+) High availability during AZ-level failures.