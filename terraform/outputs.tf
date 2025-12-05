output "redshift_namespace_id" {
  description = "Redshift Serverless namespace ID"
  value       = module.redshift.namespace_id
}

output "redshift_workgroup_endpoint" {
  description = "Redshift Serverless workgroup endpoint"
  value       = module.redshift.workgroup_endpoint
}

output "redshift_workgroup_port" {
  description = "Redshift Serverless workgroup port"
  value       = module.redshift.workgroup_port
}

output "redshift_database_name" {
  description = "Default database name"
  value       = module.redshift.database_name
}

output "redshift_iam_role_arn" {
  description = "IAM role ARN for Redshift"
  value       = module.iam.redshift_role_arn
}

output "redshift_admin_secret_arn" {
  description = "ARN of the secret containing Redshift admin credentials"
  value       = module.redshift.admin_secret_arn
  sensitive   = true
}

output "mssql_secret_arn" {
  description = "ARN of the MSSQL credentials secret"
  value       = var.mssql_secret_arn
}

output "connection_info" {
  description = "Connection information for Redshift"
  value = {
    endpoint      = module.redshift.workgroup_endpoint
    port          = module.redshift.workgroup_port
    database      = module.redshift.database_name
    admin_secret  = module.redshift.admin_secret_arn
  }
}

# DMS Outputs
output "dms_replication_instance_arn" {
  description = "ARN of the DMS replication instance"
  value       = module.dms.replication_instance_arn
}

output "dms_replication_task_arn" {
  description = "ARN of the DMS replication task"
  value       = module.dms.replication_task_arn
}

output "dms_s3_staging_bucket" {
  description = "S3 bucket for DMS staging"
  value       = module.dms.s3_staging_bucket
}
