output "namespace_id" {
  description = "Redshift Serverless namespace ID"
  value       = aws_redshiftserverless_namespace.main.id
}

output "namespace_arn" {
  description = "Redshift Serverless namespace ARN"
  value       = aws_redshiftserverless_namespace.main.arn
}

output "workgroup_id" {
  description = "Redshift Serverless workgroup ID"
  value       = aws_redshiftserverless_workgroup.main.id
}

output "workgroup_arn" {
  description = "Redshift Serverless workgroup ARN"
  value       = aws_redshiftserverless_workgroup.main.arn
}

output "workgroup_endpoint" {
  description = "Redshift Serverless workgroup endpoint"
  value       = aws_redshiftserverless_workgroup.main.endpoint[0].address
}

output "workgroup_port" {
  description = "Redshift Serverless workgroup port"
  value       = aws_redshiftserverless_workgroup.main.endpoint[0].port
}

output "admin_secret_arn" {
  description = "ARN of the secret containing Redshift admin credentials"
  value       = aws_secretsmanager_secret.redshift_admin.arn
}

output "database_name" {
  description = "Default database name"
  value       = aws_redshiftserverless_namespace.main.db_name
}
