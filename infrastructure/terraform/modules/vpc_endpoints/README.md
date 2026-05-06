### AWS VPC Endpoints Module

This module provides a secure and compliant way to connect your VPC to AWS services using Interface and Gateway Endpoints. 
By using VPC Endpoints, traffic between your VPC and AWS services does not leave the Amazon network, enhancing security and reducing data transfer costs.

This implementation is designed for regulated environments, featuring strict security group rules and endpoint policies to prevent unauthorized access and data exfiltration.

### Features

*   **Private Connectivity**: Enables private access to AWS services without requiring an Internet Gateway or NAT Gateway.
*   **Gateway Endpoints**:
    *   **S3 & DynamoDB**: Configured as Gateway Endpoints for cost-effective, high-throughput connectivity with automatic route table integration.
*   **Interface Endpoints (PrivateLink)**:
    *   Supports a comprehensive list of services: ECR (API & Docker), Secrets Manager, CloudWatch Logs, KMS, STS, EC2, Elastic Load Balancing, Auto Scaling, CloudWatch Monitoring, and X-Ray.
    *   **Private DNS Enabled**: Allows resources in the VPC to use the default AWS service DNS names while resolving to private IP addresses.
*   **Security & Compliance**:
    *   **Strict Security Group**: A dedicated security group limits ingress to HTTPS (port 443) only from within the VPC CIDR.
    *   **Access Control Policies**: Interface endpoints include a resource-based policy that restricts access to the local AWS account only (`aws:PrincipalAccount`), preventing cross-account data exfiltration.
    *   **Encryption**: All traffic to endpoints is encrypted in transit via TLS/HTTPS.

### Usage Example

```hcl
module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  env             = "prod"
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = "10.0.0.0/16"
  subnet_ids      = module.vpc.private_app_subnets
  route_table_ids = module.vpc.private_route_table_ids

  common_tags = {
    Project     = "GenovaX"
    Environment = "Production"
    ManagedBy   = "Terraform"
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

| Name                                   | Type     |
|:---------------------------------------|:---------|
| `aws_vpc_endpoint.gateway_endpoints`   | resource |
| `aws_vpc_endpoint.interface_endpoints` | resource |
| `aws_security_group.vpc_endpoints`     | resource |

### Inputs

| Name                  | Description                                                    | Type           | Default   | Required   |
|:----------------------|:---------------------------------------------------------------|:---------------|:----------|:-----------|
| **`env`**             | Name of the deployment environment (e.g., `prod`, `dev`)       | `string`       | n/a       | **yes**    |
| **`vpc_id`**          | ID of the VPC in which the endpoints will be created           | `string`       | n/a       | **yes**    |
| **`vpc_cidr`**        | VPC CIDR block for Security Group configuration                | `string`       | n/a       | **yes**    |
| **`subnet_ids`**      | List of subnet IDs for placing interface endpoints             | `list(string)` | n/a       | **yes**    |
| **`route_table_ids`** | List of routing table IDs for Gateway endpoints (S3, DynamoDB) | `list(string)` | n/a       | **yes**    |
| **`common_tags`**     | General tags for all resources                                 | `map(string)`  | n/a       | **yes**    |

### Outputs

| Name                                 | Description                                             |
|:-------------------------------------|:--------------------------------------------------------|
| **`vpc_endpoint_security_group_id`** | ID of the Security Group created for VPC Endpoints      |
| **`interface_endpoints`**            | Map of created interface endpoints and their attributes |

### Implementation Details

1.  **Endpoint Services**: The module automatically provisions interface endpoints for:
    *   `ecr.api`, `ecr.dkr` (Container Registry)
    *   `secretsmanager` (Secrets Management)
    *   `logs` (CloudWatch Logs)
    *   `kms` (Key Management Service)
    *   `sts` (Security Token Service)
    *   `ec2` (Elastic Compute Cloud)
    *   `elasticloadbalancing` (ELB)
    *   `autoscaling` (Auto Scaling)
    *   `monitoring` (CloudWatch Metrics)
    *   `xray` (AWS X-Ray)
2.  **Network Security**: The `aws_security_group.vpc_endpoints` acts as a firewall for the Interface Endpoints. It implements a "least privilege" ingress rule, allowing only TCP port 443 traffic from the specified VPC CIDR.
3.  **Data Exfiltration Prevention**: Each Interface Endpoint is configured with a JSON policy that restricts access to the specific AWS Account ID where the module is deployed. This ensures that even if a resource inside the VPC is compromised, it cannot easily be used to move data to an external AWS account via these endpoints.
4.  **Gateway Routing**: Gateway endpoints (S3 and DynamoDB) do not use security groups. Instead, they rely on routing table entries. This module attaches these endpoints to the provided list of `route_table_ids`.
