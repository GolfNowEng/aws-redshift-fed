variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "459286107047_svc_data_prod"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "redshift-fed"
}

# Existing VPC and networking resources
variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
  default     = "vpc-0e47374708b217ada"
}

variable "subnet_ids" {
  description = "Existing subnet IDs for Redshift"
  type        = list(string)
  default     = ["subnet-0f985b2a39b8e7094", "subnet-02cb1a70c7d797105"]
}

variable "security_group_ids" {
  description = "Existing security group IDs"
  type        = list(string)
  default     = ["sg-08dff1d69f471a135"]
}

# Redshift configuration
variable "redshift_namespace_name" {
  description = "Redshift Serverless namespace name"
  type        = string
  default     = "redshift-fed-prod"
}

variable "redshift_workgroup_name" {
  description = "Redshift Serverless workgroup name"
  type        = string
  default     = "redshift-fed-prod-workgroup"
}

variable "redshift_base_capacity" {
  description = "Base capacity in RPUs"
  type        = number
  default     = 32
}

variable "redshift_admin_username" {
  description = "Redshift admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

# Secrets Manager
variable "mssql_secret_arn" {
  description = "ARN of the Secrets Manager secret containing MSSQL credentials"
  type        = string
  default     = "arn:aws:secretsmanager:us-west-2:459286107047:secret:gndataeng/prod/db-mssql/raptor/analytics-KfZGux"
}

# MSSQL Database
variable "mssql_host" {
  description = "MSSQL database host"
  type        = string
  default     = "LSNRGNP04A.ad.idelb.com"
}

variable "mssql_port" {
  description = "MSSQL database port"
  type        = number
  default     = 4070
}

variable "mssql_database" {
  description = "MSSQL database name"
  type        = string
  default     = "Raptor"
}

# Tables to federate
variable "federated_tables" {
  description = "List of MSSQL tables to access via federated queries"
  type        = list(string)
  default     = ["DimLocation", "DimDate"]
}

# Logging
variable "enable_audit_logging" {
  description = "Enable Redshift audit logging"
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "S3 bucket for Redshift logs"
  type        = string
  default     = "gndataeng-redshift-logs-prod"
}
