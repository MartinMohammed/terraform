terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "game-jam-hackathon-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "game-jam-terraform-state-lock"
  }
}


provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "GameJam"
      Environment = var.environment
      Terraform   = "true"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  # Common name prefix for resources
  name_prefix = "${var.base_name}-${var.environment}"

  # Get environment specific settings
  env_settings = var.resource_settings[var.environment]

  # Common tags for all resources
  common_tags = {
    Environment = var.environment
    Project     = var.base_name
    ManagedBy   = "Terraform"
  }
}


# You can add your AWS resources here 
