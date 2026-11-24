data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

#region VPC -------------------------------------------------------------------------------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

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

  lifecycle_rule = [
    {
      id                                     = "expire-landing-zone-objects"
      enabled                                = true
      filter                                 = {}
      abort_incomplete_multipart_upload_days = 1
      expiration = {
        days = 3
      }
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
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id] // Only allow traffic from EC2.
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

  engine            = "postgres"
  engine_version    = "18.6" # `aws rds describe-db-engine-versions --engine postgres --query 'DBEngineVersions[].EngineVersion'`
  family            = "postgres18"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "${var.project_name}_${var.environment}_db"
  username = "lms_admin"
  port     = "5432"

  iam_database_authentication_enabled = true
  password_wo                         = var.rds_password
  password_wo_version                 = 1
  manage_master_user_password         = false # By default, the module will store the password in Secrets Manager

  performance_insights_enabled = false
  database_insights_mode       = null
  skip_final_snapshot          = true
  deletion_protection          = false
  backup_retention_period      = 1

  # VPC & Network
  vpc_security_group_ids = [aws_security_group.rds.id]
  subnet_ids             = module.vpc.private_subnets
  create_db_subnet_group = true
  publicly_accessible    = false
  storage_encrypted      = true
}

#endregion

#region EC2

data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2"
  description = "EC2 Access for VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project_name}-${var.environment}-server"

  instance_type        = "t4g.small"
  ami_ssm_parameter    = data.aws_ssm_parameter.al2023_arm64.name
  # create_spot_instance = true // Keep this enabled for dev, although traffic might be interrupted

  subnet_id              = module.vpc.public_subnets[0]
  create_security_group  = false
  monitoring             = false
  vpc_security_group_ids = [aws_security_group.ec2.id]

  create_iam_instance_profile = true
  iam_role_policies = {
    SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

#endregion

#region IAM Role

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:the-fundamentals/lms-core-api:*"]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "github-actions-lms-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}

resource "aws_iam_role_policy" "github_deploy_ssm" {
  name = "ssm-deploy"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:SendCommand"]
        Resource = [
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${module.ec2_instance.id}",
          "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation"]
        Resource = "*"
      }
    ]
  })
}

#endregion