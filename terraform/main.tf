# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get VPC details
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Data source to get subnet details
data "aws_subnets" "redshift" {
  filter {
    name   = "subnet-id"
    values = var.subnet_ids
  }
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  aws_account_id   = data.aws_caller_identity.current.account_id
  mssql_secret_arn = var.mssql_secret_arn
  log_bucket_name  = var.log_bucket_name
}

# Redshift Serverless Module
module "redshift" {
  source = "./modules/redshift"

  project_name    = var.project_name
  environment     = var.environment
  namespace_name  = var.redshift_namespace_name
  workgroup_name  = var.redshift_workgroup_name
  admin_username  = var.redshift_admin_username
  base_capacity   = var.redshift_base_capacity

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  iam_role_arn       = module.iam.redshift_role_arn

  enable_audit_logging = var.enable_audit_logging

  depends_on = [module.iam]
}
