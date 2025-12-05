terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "gndataeng-terraform-state-prod"
    key            = "redshift-federated/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "gndataeng-terraform-lock-prod"
    profile        = "459286107047_svc_data_prod"
  }
}
