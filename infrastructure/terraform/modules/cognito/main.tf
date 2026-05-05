terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}

resource "aws_cognito_user_pool" "pool" {
  name = var.user_pool_name

  deletion_protection = "ACTIVE"
  mfa_configuration = "ON"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers = true
    require_symbols = true
    password_history_size = 5
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  tags = merge(var.common_tags, {
    Name = var.user_pool_name
  })
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.user_pool_name}-${var.env}"
  user_pool_id = aws_cognito_user_pool.pool.id
}

# Cognito Identity Provider for Office 365 (Azure AD)
# Note: In Azure AD, you must configure an Enterprise Application with:
# Identifier (Entity ID): urn:amazon:cognito:sp:${aws_cognito_user_pool.pool.id}
# Reply URL: https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/saml2/idpresponse
resource "aws_cognito_identity_provider" "office365" {
  user_pool_id  = aws_cognito_user_pool.pool.id
  provider_name = "Office365"
  provider_type = "SAML"

  provider_details = {
    MetadataURL = var.office365_idp_metadata_url
  }

  attribute_mapping = {
    email       = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
    given_name  = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
    family_name = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name = "${var.user_pool_name}-client"

  user_pool_id = aws_cognito_user_pool.pool.id

  supported_identity_providers = ["COGNITO", aws_cognito_identity_provider.office365.provider_name]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

