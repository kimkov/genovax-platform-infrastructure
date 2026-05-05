### AWS ACM Module (AWS Certificate Manager)

This Terraform module is designed to manage SSL/TLS certificates in AWS Certificate Manager. 
It automates the process of requesting a certificate, creating validation records in Route53, and waiting for the validation to complete.

### Features

- **Public Certificate Request**: Requests an SSL/TLS certificate for the specified domain.
- **SAN (Subject Alternative Names) Support**: Allows adding additional domains (e.g., wildcards) to a single certificate.
- **Automatic DNS Validation**: The module automatically creates the necessary CNAME records in the specified Route53 zone to pass domain ownership verification.
- **Readiness Control**: Uses the `aws_acm_certificate_validation` resource, ensuring Terraform does not proceed to creating dependent resources (e.g., ALB) until the certificate status is `ISSUED`.
- **Secure Updates**: Configured with the `create_before_destroy` lifecycle hook, preventing TLS connection interruptions during certificate recreation.

### Usage Example

```hcl
module "acm" {
  source = "../../modules/acm"

  env                       = "prod"
  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com", "api.example.com"]
  zone_id                   = "00000000000000000"
  
  common_tags = {
    Project = "Platform"
    Owner   = "DevOps Team"
  }
}
```

### Requirements

| Name        | Version    |
|:------------|:-----------|
| `terraform` | `>= 1.5.0` |
| `aws`       | `>= 5.0`   |

### Providers

| Name     | Version    |
|:---------|:-----------|
| `aws`    | `>= 5.0`   |

### Resources

| Name                                                                                                                                            | Type     |
|:------------------------------------------------------------------------------------------------------------------------------------------------|:---------|
| [`aws_acm_certificate.this`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate)                       | resource |
| [`aws_acm_certificate_validation.this`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [`aws_route53_record.validation`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                   | resource |

### Inputs

| Name                            | Description                                               |      Type      |  Default  |  Required   |
|:--------------------------------|:----------------------------------------------------------|:--------------:|:---------:|:-----------:|
| **`domain_name`**               | Primary domain name for the certificate.                  |    `string`    |    n/a    |     yes     |
| **`zone_id`**                   | Route53 Zone ID where validation records will be created. |    `string`    |    n/a    |     yes     |
| **`env`**                       | Environment name (e.g., `prod`, `dev`, `stage`).          |    `string`    |    n/a    |     yes     |
| **`subject_alternative_names`** | List of Subject Alternative Names (SAN).                  | `list(string)` |   `[]`    |     no      |
| **`common_tags`**               | A map of tags to apply to all resources.                  | `map(string)`  |   `{}`    |     no      |

### Outputs

| Name                     | Description                                                                       |
|:-------------------------|:----------------------------------------------------------------------------------|
| **`certificate_arn`**    | ARN of the verified and ready-to-use certificate. Pass this to ALB or CloudFront. |
| **`certificate_domain`** | The primary domain name for which the certificate was issued.                     |

### Implementation Details

1. **Dynamic Validation**: The module uses a `for_each` loop to create DNS records, allowing it to correctly handle any number of domains specified in the certificate.
2. **Record TTL**: DNS validation records are set with a TTL of 60 seconds to speed up the validation process during the initial setup.
3. **Naming Convention**: The `Name` tag for the certificate is automatically generated using the format `${env}-${domain_name}-cert`.