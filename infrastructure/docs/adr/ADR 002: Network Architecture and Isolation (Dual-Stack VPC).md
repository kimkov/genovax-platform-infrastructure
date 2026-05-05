Status: Accepted
Context:
    Need to ensure PHI data traffic isolation from the public internet and optimize data transfer costs.

Decision:
    Implement a **VPC with Dual-stack (IPv4/IPv6) support** and a three-tier subnet architecture:

1. Public Subnets: Strictly for ALB and NAT Gateway.
2. Private App Subnets: For EKS nodes and VPC Endpoints.
3. Private Data Subnets: Isolated subnets for RDS and S3.
4. VPC Endpoints (PrivateLink): Use interface endpoints for S3, ECR, KMS, and Logs to ensure traffic remains within the AWS network.

Consequences:
    (+) AWS service traffic is protected from interception on the public web.
    (+) Reduced NAT Gateway costs.
    (+) Support for modern IPv6 standards.