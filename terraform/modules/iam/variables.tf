variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "mssql_secret_arn" {
  description = "ARN of the Secrets Manager secret containing MSSQL credentials"
  type        = string
}

variable "log_bucket_name" {
  description = "S3 bucket name for logs"
  type        = string
}
