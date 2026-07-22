output "cognito_user_pool_id" {
  description = "Cognito user pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "Cognito website app client ID"
  value       = module.cognito.app_client_id
}

output "cognito_hosted_ui_domain" {
  description = "Cognito hosted UI domain"
  value       = module.cognito.hosted_ui_domain
}

output "cognito_dummy_user_email" {
  description = "Dummy USER Cognito account email"
  value       = module.cognito.dummy_user_email
}

output "cognito_dummy_admin_email" {
  description = "Dummy ADMIN Cognito account email"
  value       = module.cognito.dummy_admin_email
}

output "cognito_dummy_password" {
  description = "Shared password for dummy Cognito accounts"
  value       = module.cognito.dummy_password
  sensitive   = true
}
