variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "namespace_name" {
  description = "Redshift Serverless namespace name"
  type        = string
}

variable "workgroup_name" {
  description = "Redshift Serverless workgroup name"
  type        = string
}

variable "database_name" {
  description = "Default database name"
  type        = string
  default     = "dev"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "base_capacity" {
  description = "Base capacity in RPUs"
  type        = number
  default     = 32
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "iam_role_arn" {
  description = "IAM role ARN for Redshift"
  type        = string
}

variable "enable_audit_logging" {
  description = "Enable audit logging"
  type        = bool
  default     = true
}
