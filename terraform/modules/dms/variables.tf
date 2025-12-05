variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DMS replication instance"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for DMS replication instance"
  type        = list(string)
}

# DMS Replication Instance
variable "replication_instance_class" {
  description = "DMS replication instance class"
  type        = string
  default     = "dms.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GB for DMS replication instance"
  type        = number
  default     = 100
}

variable "engine_version" {
  description = "DMS engine version"
  type        = string
  default     = "3.5.2"
}

variable "multi_az" {
  description = "Enable Multi-AZ for DMS replication instance"
  type        = bool
  default     = false
}

# Source Endpoint (SQL Server)
variable "source_server_name" {
  description = "SQL Server hostname"
  type        = string
}

variable "source_port" {
  description = "SQL Server port"
  type        = number
  default     = 4070
}

variable "source_database_name" {
  description = "SQL Server database name"
  type        = string
}

variable "source_username" {
  description = "SQL Server username"
  type        = string
  sensitive   = true
}

variable "source_password" {
  description = "SQL Server password"
  type        = string
  sensitive   = true
}

# Target Endpoint (Redshift)
variable "target_server_name" {
  description = "Redshift hostname"
  type        = string
}

variable "target_port" {
  description = "Redshift port"
  type        = number
  default     = 5439
}

variable "target_database_name" {
  description = "Redshift database name"
  type        = string
}

variable "target_username" {
  description = "Redshift username"
  type        = string
  sensitive   = true
}

variable "target_password" {
  description = "Redshift password"
  type        = string
  sensitive   = true
}

# S3 and IAM
variable "s3_bucket_name" {
  description = "S3 bucket name for DMS staging"
  type        = string
}

variable "dms_service_role_arn" {
  description = "IAM role ARN for DMS to access S3"
  type        = string
}

# Table Mappings
variable "table_mappings" {
  description = "DMS table mappings JSON"
  type        = string
}
