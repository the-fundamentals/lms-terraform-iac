variable "user_pool_name" {
  type        = string
  description = "Name of the Cognito user pool"
}

variable "app_client_name" {
  type        = string
  description = "Name of the Cognito app client used by the website"
}

variable "domain_prefix" {
  type        = string
  description = "Cognito hosted UI domain prefix (must be globally unique)"
}

variable "callback_urls" {
  type        = list(string)
  description = "OAuth callback URLs for the authorization code flow"
}

variable "logout_urls" {
  type        = list(string)
  description = "OAuth logout URLs for the website"
}

variable "dummy_user_email" {
  type        = string
  description = "Email/username for the bootstrap USER dummy account"
}

variable "dummy_admin_email" {
  type        = string
  description = "Email/username for the bootstrap ADMIN dummy account"
}

variable "dummy_password" {
  type        = string
  description = "Shared password for dummy Cognito accounts"
  sensitive   = true
}
