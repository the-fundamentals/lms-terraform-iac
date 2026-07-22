data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  public_subnet_cidrs = [
    for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)
  ]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs            = local.azs
  public_subnets = local.public_subnet_cidrs

  enable_nat_gateway = false
  enable_vpn_gateway = false
  create_igw = true

  map_public_ip_on_launch = true
}

resource "random_id" "cognito_domain" {
  byte_length = 4
}

module "cognito" {
  source = "./modules/cognito"

  user_pool_name  = "${var.project_name}-${var.environment}-users"
  app_client_name = "${var.project_name}-${var.environment}-management-web"
  domain_prefix   = "${var.project_name}-${var.environment}-${random_id.cognito_domain.hex}"

  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls

  dummy_user_email  = var.cognito_dummy_user_email
  dummy_admin_email = var.cognito_dummy_admin_email
  dummy_password    = var.cognito_dummy_password
}

# module "ecs" {
#   source = "terraform-aws-modules/ecs/aws"
# }