terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # You'll need to configure these values based on your S3 bucket
    bucket = "game-jam-hackathon-terraform-state"
    key    = "game-jam/terraform.tfstate"
    region = "eu-west-1"
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
