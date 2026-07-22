resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = false
    require_numbers                  = false
    require_symbols                  = false
    require_uppercase                = false
    temporary_password_validity_days = 7
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }
}

data "aws_region" "current" {}


resource "aws_cognito_user_pool_domain" "this" {
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "aws_cognito_user_pool_client" "management_web" {
  name         = var.app_client_name
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  prevent_user_existence_errors = "ENABLED"

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_group" "user" {
  name         = "USER"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Standard application users"
  precedence   = 20
}

resource "aws_cognito_user_group" "admin" {
  name         = "ADMIN"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "Application administrators"
  precedence   = 1
}

resource "aws_cognito_user" "dummy_user" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = var.dummy_user_email

  attributes = {
    email          = var.dummy_user_email
    email_verified = "true"
  }

  password       = var.dummy_password
  message_action = "SUPPRESS"

  depends_on = [aws_cognito_user_group.user]
}

resource "aws_cognito_user" "dummy_admin" {
  user_pool_id = aws_cognito_user_pool.this.id
  username     = var.dummy_admin_email

  attributes = {
    email          = var.dummy_admin_email
    email_verified = "true"
  }

  password       = var.dummy_password
  message_action = "SUPPRESS"

  depends_on = [aws_cognito_user_group.admin]
}

resource "aws_cognito_user_in_group" "dummy_user" {
  user_pool_id = aws_cognito_user_pool.this.id
  group_name   = aws_cognito_user_group.user.name
  username     = aws_cognito_user.dummy_user.username
}

resource "aws_cognito_user_in_group" "dummy_admin" {
  user_pool_id = aws_cognito_user_pool.this.id
  group_name   = aws_cognito_user_group.admin.name
  username     = aws_cognito_user.dummy_admin.username
}
