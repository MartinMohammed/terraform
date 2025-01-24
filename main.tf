terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # You'll need to configure these values based on your S3 bucket
    # bucket = "your-terraform-state-bucket"
    # key    = "game-jam/terraform.tfstate"
    # region = "us-east-1"
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
