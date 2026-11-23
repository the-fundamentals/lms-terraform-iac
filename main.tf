data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  public_subnet_cidrs = [
    for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)
  ]

  private_subnet_cidrs = [
    for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + var.az_count)
  ]
}

#region VPC -------------------------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs            = local.azs
  public_subnets = local.public_subnet_cidrs
  private_subnets = local.private_subnet_cidrs

  enable_nat_gateway = false
  enable_vpn_gateway = false
  create_igw         = true

  map_public_ip_on_launch = true
}

#endregion

#region COGNITO -------------------------------------------------------------------------------------------

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

#endregion

#region S3 -------------------------------------------------------------------------------------------

module "s3_landing_zone" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.project_name}-${var.environment}-${var.uniqueness_token}-landing-zone"

  force_destroy     = true
  block_public_acls = false
  cors_rule = [
    {
      allowed_methods = ["GET", "PUT", "POST"],
      allowed_origins = ["http://localhost:3000"],
      allowed_headers = ["*"]
    }
  ]
}

module "s3_public" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.project_name}-${var.environment}-${var.uniqueness_token}-public"

  force_destroy = true

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${var.project_name}-${var.environment}-${var.uniqueness_token}-public/*"
      }
    ]
  })

  cors_rule = [
    {
      allowed_methods = ["GET", "PUT", "POST"],
      allowed_origins = ["http://localhost:3000"],
      allowed_headers = ["*"]
    }
  ]
}

#endregion -------------------------------------------------------------------------------------------

#region RDS -------------------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds"
  description = "Postgres access for LMS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.project_name}-${var.environment}-rds"

  engine               = "postgresql"
  engine_version       = "18.3-R2"
  instance_class       = "db.t4g.micro"
  allocated_storage    = 20
  storage_type         = "gp3"

  db_name  = "${var.project_name}-${var.environment}-db"
  username = "admin"
  port     = "5432"

  password_wo = var.rds_password

  # VPC & Network
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  subnet_ids             = module.vpc.private_subnets
}

#endregion