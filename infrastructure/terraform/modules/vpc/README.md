### AWS VPC Infrastructure Module

This module provides a secure, multi-AZ networking foundation for the Platform platform. It is designed to meet HIPAA compliance requirements 
by ensuring strict network isolation, comprehensive traffic auditing, and high availability.

### Features

*   **Network Segmentation**:
    *   **Public Subnets**: Provisioned for Internet Gateways and NAT Gateways.
    *   **Private App Subnets**: Isolated subnets dedicated to application workloads, EKS worker nodes, and internal services.
*   **Security & Compliance**:
    *   **VPC Flow Logs**: Enabled for all traffic (Accept/Reject), with logs delivered to a centralized S3 bucket for audit trails and security analysis.
    *   **Hardened Default Security Group**: The default security group is fully restricted (no ingress or egress) to prevent accidental resource exposure.
    *   **Network ACLs (NACLs)**: Private subnets are protected by dedicated NACLs with a "least privilege" egress policy.
*   **High Availability**:
    *   **Multi-AZ Redundancy**: Subnets are distributed across multiple Availability Zones to ensure service continuity.
    *   **Dedicated NAT Gateways**: One NAT Gateway per AZ provides fault isolation, ensuring that a failure in one zone does not affect outbound connectivity for others.
*   **IPv6 Support**:
    *   **Dual-Stack Capability**: Support for both IPv4 and IPv6 networking.
    *   **Egress-Only Internet Gateway**: Allows IPv6-enabled instances in private subnets to initiate outbound connections while remaining protected from unsolicited inbound traffic.
*   **EKS Integration**:
    *   Subnets are automatically tagged with `kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb` for seamless discovery and integration with the AWS Load Balancer Controller.

### Usage Example

```hcl
module "vpc" {
  source = "../../modules/vpc"

  env                = "prod"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["region-1", "region-2", "region-3"]
  log_bucket_id      = "platform-prod-vpc-flow-logs"
  kms_key_arn        = "arn:aws:kms:region-1:000000000000:key/your-key-id"

  common_tags = {
    Project = "Platform"
    Owner   = "PlatformTeam"
  }
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `>= 5.0`   |

### Providers

| Name   | Version   | Description          |
|:-------|:----------|:---------------------|
| `aws`  | `>= 5.0`  | Primary AWS provider |

### Resources

| Name                                    | Type     |
|:----------------------------------------|:---------|
| `aws_vpc.main`                          | resource |
| `aws_subnet.public`                     | resource |
| `aws_subnet.private_app`                | resource |
| `aws_internet_gateway.main`             | resource |
| `aws_egress_only_internet_gateway.main` | resource |
| `aws_nat_gateway.main`                  | resource |
| `aws_eip.nat`                           | resource |
| `aws_route_table.public`                | resource |
| `aws_route_table.private`               | resource |
| `aws_flow_log.main`                     | resource |
| `aws_network_acl.private`               | resource |
| `aws_default_security_group.default`    | resource |

### Inputs

| Name                                   | Description                                                           | Type           | Default          | Required   |
|:---------------------------------------|:----------------------------------------------------------------------|:---------------|:-----------------|:-----------|
| **`env`**                              | Deployment environment name (e.g., `prod`, `dev`)                     | `string`       | n/a              | **yes**    |
| **`vpc_cidr`**                         | The IPv4 CIDR block for the VPC                                       | `string`       | n/a              | **yes**    |
| **`availability_zones`**               | A list of availability zones in the region for subnet distribution    | `list(string)` | n/a              | **yes**    |
| **`kms_key_arn`**                      | ARN of the KMS key for encrypting resources (reserved for future use) | `string`       | n/a              | **yes**    |
| **`log_bucket_id`**                    | The ID (name) of the S3 bucket where VPC Flow Logs will be stored     | `string`       | n/a              | **yes**    |
| **`common_tags`**                      | General tags for all resources                                        | `map(string)`  | `{...}`          | no         |
| **`owner`**                            | Resource Owner (Team or Department)                                   | `string`       | `"PlatformTeam"` | no         |
| **`enable_ipv6`**                      | Enables IPv6 support for the VPC and subnets                          | `bool`         | `true`           | no         |
| **`assign_generated_ipv6_cidr_block`** | Requests an Amazon-provided IPv6 CIDR block for the VPC               | `bool`         | `true`           | no         |

### Outputs

| Name                          | Description                                |
|:------------------------------|:-------------------------------------------|
| **`vpc_id`**                  | The ID of the VPC                          |
| **`vpc_cidr`**                | The CIDR block of the VPC                  |
| **`private_app_subnets`**     | List of IDs of private application subnets |
| **`public_subnets`**          | List of IDs of public subnets              |
| **`flow_log_bucket_id`**      | The S3 bucket ID used for flow logs        |
| **`private_route_table_ids`** | List of IDs of private route tables        |
| **`public_route_table_id`**   | The ID of the public route table           |

### Implementation Details

1.  **NAT Strategy**: This module implements a "NAT Gateway per AZ" architecture. This ensures that an Availability Zone outage does not impact the connectivity of workloads in other zones, providing maximum availability for critical workloads.
2.  **Traffic Auditing**: VPC Flow Logs are configured to capture `ALL` traffic types. Integration with S3 ensures persistent storage for security audits and compliance verification.
3.  **Default Deny Posture**: By adopting and stripping all rules from the `aws_default_security_group`, the module ensures that the VPC remains secure by default. Any resource created in the VPC must be explicitly associated with a custom security group to communicate.
4.  **Routing**: Private subnets are routed through their respective AZ's NAT Gateway for IPv4 and the Egress-Only Internet Gateway for IPv6, maintaining a "private-by-default" posture while allowing necessary outbound access.
5.  **NACL Hardening**: The private subnet NACL provides defense-in-depth by explicitly limiting egress to common service ports (HTTPS/443, DNS/53 UDP) and ephemeral ranges (1024-65535 TCP), while allowing all internal VPC traffic.
