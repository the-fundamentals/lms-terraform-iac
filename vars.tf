variable "aws_region" {
  type        = string
  description = "The region to be used by AWS"
  default     = "ap-southeast-1"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
  default     = "lms"
}

variable "uniqueness_token" {
  type        = string
  description = "A uniqueness token for S3 bucket names"
  default     = "fundamentals000"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones (and public subnets) to use"
  default     = 3
}

variable "environment" {
  type        = string
  description = "Environment to deploy in"
  default     = "local"
}

variable "cognito_callback_urls" {
  type        = list(string)
  description = "OAuth callback URLs for the website authorization code flow (include Swagger UI redirect for SpringDoc Authorize)"
  default = [
    "http://localhost:3000/callback",
    "http://localhost:8080/swagger-ui/oauth2-redirect.html",
    "http://localhost:3000/sign-in"
  ]
}

variable "cognito_logout_urls" {
  type        = list(string)
  description = "OAuth logout URLs for the website"
  default     = ["http://localhost:3000/"]
}

variable "cognito_dummy_user_email" {
  type        = string
  description = "Email for the bootstrap USER Cognito account. Empty skips create."
  default     = ""
}

variable "cognito_dummy_admin_email" {
  type        = string
  description = "Email for the bootstrap ADMIN Cognito account. Empty skips create."
  default     = ""
}

variable "cognito_dummy_password" {
  type        = string
  description = "Shared password for dummy Cognito accounts. Empty skips create."
  default     = ""
  sensitive   = true
}

variable "rds_password" {
  type        = string
  description = "RDS Database Password"
  default     = ""
  sensitive   = true
}
