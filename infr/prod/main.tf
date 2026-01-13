
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket               = "devops-ml-tf-state"
    key                  = "tf-state-prod"
    workspace_key_prefix = "tf-state-prod-env"
    region               = "us-east-1"
    encrypt              = true
    use_lockfile         = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      contact     = var.contact
      ManagedBy   = "Terraform/prod"
    }
  }
}

locals {
  prefix = "${var.prefix}-${terraform.workspace}"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}