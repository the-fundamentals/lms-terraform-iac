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

output "public_s3_bucket" {
  value       = module.s3_public.s3_bucket_id
  description = "Name of the Public S3 Bucket"
}

resource "local_file" "env_local" {
  count    = var.environment == "local" ? 1 : 0
  filename = "${path.module}/.env.local"
  content  = <<-EOT
VITE_COGNITO_REGION=${var.aws_region}
VITE_COGNITO_USER_POOL_ID=${module.cognito.user_pool_id}
VITE_COGNITO_CLIENT_ID=${module.cognito.app_client_id}
VITE_COGNITO_DOMAIN=http://localhost.localstack.cloud:4566/_aws/cognito-idp
VITE_PUBLIC_STORAGE_BASE_URL=http://localhost.localstack.cloud:4566/${module.s3_public.s3_bucket_id}

COGNITO_USER_POOL_ID=${module.cognito.user_pool_id}
COGNITO_APP_CLIENT_ID=${module.cognito.app_client_id}
COGNITO_BASE_DOMAIN=http://localhost.localstack.cloud:4566
EOT
}

output "github_deploy_role_arn" {
  value = aws_iam_role.github_deploy.arn
}