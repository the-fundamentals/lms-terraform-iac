output "user_pool_id" {
  description = "Cognito user pool ID"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "Cognito user pool ARN"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  description = "Cognito user pool endpoint"
  value       = aws_cognito_user_pool.this.endpoint
}

output "app_client_id" {
  description = "Website app client ID"
  value       = aws_cognito_user_pool_client.management_web.id
}

output "hosted_ui_domain" {
  description = "Cognito hosted UI domain"
  value       = "${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.region}.amazoncognito.com"
}

output "dummy_user_email" {
  description = "Dummy USER account email"
  value       = aws_cognito_user.dummy_user.username
}

output "dummy_admin_email" {
  description = "Dummy ADMIN account email"
  value       = aws_cognito_user.dummy_admin.username
}

output "dummy_password" {
  description = "Shared password for dummy accounts"
  value       = var.dummy_password
  sensitive   = true
}

output "user_group_name" {
  description = "USER group name"
  value       = aws_cognito_user_group.user.name
}

output "admin_group_name" {
  description = "ADMIN group name"
  value       = aws_cognito_user_group.admin.name
}
