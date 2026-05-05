### AWS Cognito Module

This module provides a production-ready and highly secure implementation of **AWS Cognito User Pools**, 
featuring native integration with **Office 365 (Azure AD)** via SAML 2.0. It is designed to manage user identities, 
authentication, and authorization for the GenovaX ecosystem, adhering to strict security standards.

### Features

*   **Security & Compliance**:
    *   **MFA (Multi-Factor Authentication)**: Enforced (`ON`) to ensure an additional layer of security for all users.
    *   **Advanced Security Mode**: Set to `ENFORCED` to enable threat detection and protection against credential compromise.
    *   **Deletion Protection**: Active to prevent accidental removal of the User Pool and its data.
    *   **Hardened Password Policy**: Requires a minimum length of 12 characters, including uppercase, lowercase, numbers, and symbols, with a password history of 5.
*   **Identity Federation (SSO)**:
    *   **Office 365 Integration**: Built-in SAML 2.0 Identity Provider configuration for seamless Single Sign-On with Azure AD.
    *   **Attribute Mapping**: Automatically maps standard Azure AD claims (email, given name, surname) to Cognito user attributes.
*   **User Management**:
    *   **Admin-Only Onboarding**: Configured so that only administrators can create users, suitable for controlled enterprise environments.
*   **App Integration**:
    *   **OAuth 2.0 Client**: Includes a User Pool Client supporting the **Authorization Code** grant flow.
    *   **Scoped Access**: Supports `openid`, `email`, `profile`, and `aws.cognito.signin.user.admin` scopes.
    *   **Custom Domain**: Automatically creates a User Pool domain prefix for the hosted UI.

### Azure AD / Office 365 Configuration

To enable SAML federation, you must configure an **Enterprise Application** in the Azure Portal (Azure AD) with the following details:

*   **Identifier (Entity ID)**: `urn:amazon:cognito:sp:<user_pool_id>`
*   **Reply URL (Assertion Consumer Service)**: `https://<user_pool_domain>.auth.<region>.amazoncognito.com/saml2/idpresponse`
*   **Metadata URL**: Provide the "App Federation Metadata URL" from Azure AD as the `office365_idp_metadata_url` variable.

### Usage Example

```hcl
module "cognito" {
  source = "../../modules/cognito"

  env            = "prod"
  user_pool_name = "example-production-auth"
  
  office365_idp_metadata_url = "https://login.microsoftonline.com/your-tenant-id/federationmetadata/2007-06/federationmetadata.xml?appid=your-app-id"

  callback_urls = ["https://app.example.com/callback"]
  logout_urls   = ["https://app.example.com/logout"]

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

| Name   | Version  |
|:-------|:---------|
| `aws`  | `>= 5.0` |

### Resources

| Name                                                                                                                                             | Type        |
|:-------------------------------------------------------------------------------------------------------------------------------------------------|:------------|
| [aws_cognito_user_pool.pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool)                      | resource    |
| [aws_cognito_user_pool_domain.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain)        | resource    |
| [aws_cognito_identity_provider.office365](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_provider) | resource    |
| [aws_cognito_user_pool_client.client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client)      | resource    |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                      | data source |

### Inputs

| Name                             | Description                                         | Type           | Default   | Required   |
|:---------------------------------|:----------------------------------------------------|:---------------|:----------|:-----------|
| **`env`**                        | Environment name (e.g., `prod`, `dev`)              | `string`       | n/a       | **yes**    |
| **`user_pool_name`**             | The name of the Cognito User Pool                   | `string`       | n/a       | **yes**    |
| **`office365_idp_metadata_url`** | SAML metadata URL provided by Azure AD / Office 365 | `string`       | n/a       | **yes**    |
| **`callback_urls`**              | List of allowed callback URLs for the application   | `list(string)` | `[]`      | no         |
| **`logout_urls`**                | List of allowed logout URLs for the application     | `list(string)` | `[]`      | no         |
| **`common_tags`**                | A map of tags to assign to all resources            | `map(string)`  | `{}`      | no         |

### Outputs

| Name                      | Description                                              |
|:--------------------------|:---------------------------------------------------------|
| **`user_pool_id`**        | The ID of the Cognito User Pool.                         |
| **`user_pool_arn`**       | The ARN of the Cognito User Pool.                        |
| **`user_pool_client_id`** | The ID of the User Pool Client application.              |
| **`user_pool_domain`**    | The custom domain prefix used for the Cognito Hosted UI. |

### Implementation Details

1.  **Identity Federation**: The module creates a SAML 2.0 Identity Provider named `Office365`. It maps Azure AD claims to Cognito standard attributes (email, name, family name).
2.  **Authentication Flows**: The client supports authorization code flow and explicit authentication flows including SRP and password-based auth.
3.  **Domain Mapping**: The User Pool domain is automatically formatted as `${var.user_pool_name}-${var.env}` to ensure uniqueness across environments.
