variable "env" {
  description = "Environment name"
  type        = string
}

variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "office365_idp_metadata_url" {
  description = "Office 365 (Azure AD) SAML metadata URL"
  type        = string
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the client"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the client"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
