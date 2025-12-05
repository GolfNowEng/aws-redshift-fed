output "redshift_role_arn" {
  description = "ARN of the Redshift IAM role"
  value       = aws_iam_role.redshift_serverless.arn
}

output "redshift_role_name" {
  description = "Name of the Redshift IAM role"
  value       = aws_iam_role.redshift_serverless.name
}
