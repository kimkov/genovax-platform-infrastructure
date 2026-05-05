### AWS Load Balancer Controller Module

This Terraform module is designed to deploy the **AWS Load Balancer Controller** to an Amazon EKS cluster. 
The controller automates the management of AWS Elastic Load Balancers (ALB and NLB) by satisfying Kubernetes Ingress and Service resources, 
enabling seamless integration between AWS networking and Kubernetes.

### Features

- **Helm-based Deployment**: Deploys the controller using the official `aws-load-balancer-controller` Helm chart.
- **IRSA Integration**: Configured to work with IAM Roles for Service Accounts (IRSA), ensuring the controller has the necessary permissions to manage AWS resources securely.
- **Dual-Stack Support**: Default configuration includes `dualstack` IP address type, supporting both IPv4 and IPv6 traffic.
- **Ready for Production**: Pins the chart version to `1.7.2` and automates the creation of the required ServiceAccount with appropriate IAM role annotations.

### Usage Example

```hcl
module "alb_controller" {
  source = "../../modules/alb"

  cluster_name = "example-prod-cluster"
  vpc_id       = module.vpc.vpc_id
  aws_region   = "region"
  role_arn     = "arn:aws:iam::000000000000:role/Platform-prod-lbc-role"
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `helm`      | `>= 2.0`   |
| `aws`       | `>= 5.0`   |

### Providers

| Name   | Version   |
|:-------|:----------|
| `helm` | `>= 2.0`  |

### Resources

| Name                                                                                                       | Type     |
|:-----------------------------------------------------------------------------------------------------------|:---------|
| [`helm_release.lbc`](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |

### Inputs

| Name               | Description                                                     |   Type   | Default   | Required   |
|:-------------------|:----------------------------------------------------------------|:--------:|-----------|------------|
| **`cluster_name`** | Name of the EKS cluster where the controller will be installed. | `string` |    n/a    |    yes     |
| **`vpc_id`**       | VPC ID where the EKS cluster and Load Balancers are located.    | `string` |    n/a    |    yes     |
| **`aws_region`**   | AWS region for the deployment.                                  | `string` |    n/a    |    yes     |
| **`role_arn`**     | IAM Role ARN for the Load Balancer Controller (IRSA).           | `string` |    n/a    |    yes     |

### Outputs

*This module does not currently provide any exported outputs.*

### Implementation Details

1.  **Namespace**: The controller is deployed into the `kube-system` namespace to align with Kubernetes best practices for cluster-wide add-ons.
2.  **Service Account**: The module creates a ServiceAccount named `aws-load-balancer-controller` and links it to the provided IAM Role via the `eks.amazonaws.com/role-arn` annotation.
3.  **Networking**: The `ipAddressType` is explicitly set to `dualstack`. This is a critical configuration for the **Platform** infrastructure to support modern IPv6 networking requirements.
4.  **Stability**: The Helm chart version is locked to `1.7.2` to ensure consistent deployments across different environments and prevent breaking changes from upstream updates.
