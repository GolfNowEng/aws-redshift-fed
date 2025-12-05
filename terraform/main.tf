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

# Get MSSQL credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "mssql" {
  secret_id = var.mssql_secret_arn
}

# Get Redshift admin credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "redshift_admin" {
  secret_id = module.redshift.admin_secret_arn
}

locals {
  mssql_credentials     = jsondecode(data.aws_secretsmanager_secret_version.mssql.secret_string)
  redshift_credentials  = jsondecode(data.aws_secretsmanager_secret_version.redshift_admin.secret_string)
  table_mappings        = file("${path.module}/dms-table-mappings.json")
}

# DMS IAM Module
module "dms_iam" {
  source = "./modules/dms-iam"

  project_name   = var.project_name
  environment    = var.environment
  s3_bucket_name = "${var.project_name}-${var.environment}-dms-staging"
}

# DMS Module
module "dms" {
  source = "./modules/dms"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  # Replication Instance
  replication_instance_class = var.dms_replication_instance_class
  allocated_storage         = var.dms_allocated_storage
  multi_az                  = var.dms_multi_az

  # Source (SQL Server)
  source_server_name   = var.mssql_host
  source_port          = var.mssql_port
  source_database_name = var.mssql_database
  source_username      = local.mssql_credentials.username
  source_password      = local.mssql_credentials.password

  # Target (Redshift)
  target_server_name   = module.redshift.workgroup_endpoint
  target_port          = module.redshift.workgroup_port
  target_database_name = module.redshift.database_name
  target_username      = local.redshift_credentials.username
  target_password      = local.redshift_credentials.password

  # S3 and IAM
  s3_bucket_name       = "${var.project_name}-${var.environment}-dms-staging"
  dms_service_role_arn = module.dms_iam.dms_s3_role_arn

  # Table Mappings
  table_mappings = local.table_mappings

  depends_on = [
    module.redshift,
    module.dms_iam
  ]
}
