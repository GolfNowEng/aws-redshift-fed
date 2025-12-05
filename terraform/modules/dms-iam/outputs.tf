output "dms_vpc_role_arn" {
  description = "ARN of the DMS VPC management role"
  value       = aws_iam_role.dms_vpc_role.arn
}

output "dms_cloudwatch_logs_role_arn" {
  description = "ARN of the DMS CloudWatch Logs role"
  value       = aws_iam_role.dms_cloudwatch_logs_role.arn
}

output "dms_s3_role_arn" {
  description = "ARN of the DMS S3 access role"
  value       = aws_iam_role.dms_s3_role.arn
}
