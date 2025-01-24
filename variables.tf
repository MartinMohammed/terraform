variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

# S3 Backend Configuration
variable "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "game-jam-hackathon-terraform-state"
}

variable "terraform_state_key" {
  description = "Path to the state file inside the S3 bucket"
  type        = string
  default     = "game-jam/terraform.tfstate"
}

variable "terraform_state_region" {
  description = "AWS region where the S3 bucket is located"
  type        = string
  default     = "eu-central-1"
}

variable "terraform_state_dynamodb_table" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "game-jam-terraform-state-lock"
}
