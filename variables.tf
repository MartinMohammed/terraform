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
  default     = "terraform.tfstate"
}
