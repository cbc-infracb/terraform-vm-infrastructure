# Terraform version and provider constraints
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state in production
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "vm-infrastructure/terraform.tfstate"
  #   region = "us-west-2"
  #   encrypt = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  # Security best practice: Use default tags for all resources
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}