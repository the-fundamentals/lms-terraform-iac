locals {
  env-local-lms-core-api = {
    COGNITO_BASE_DOMAIN   = "http://localhost.localstack.cloud:4566"
    COGNITO_APP_CLIENT_ID = module.cognito.app_client_id
    COGNITO_USER_POOL_ID  = module.cognito.user_pool_id
  }
}

resource "local_file" "env-local-lms-core-api" {
  filename = "${path.root}/../locals/lms-core-api.env"
  count    = var.environment == "local" ? 1 : 0

  content = join("\n", [
    for key, value in local.env-local-lms-core-api :
    try(
      "${key}=[${join(", ", [for v in value : "\"${v}\""])}]",
      "${key}=${value}"
    )
  ])
}
