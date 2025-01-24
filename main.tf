terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = var.terraform_state_bucket
    key    = var.terraform_state_key
    region = var.aws_region
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "GameJam"
      Environment = var.environment
      Terraform   = "true"
    }
  }
}


# You can add your AWS resources here 
