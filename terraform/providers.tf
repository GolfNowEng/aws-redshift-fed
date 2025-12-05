provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "RedshiftFederatedQuery"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Team        = "DataEngineering"
    }
  }
}
