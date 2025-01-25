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

variable "base_name" {
  description = "Base name for all resources (e.g., 'fastapi' or 'game-jam')"
  type        = string
  default     = "fastapi" # You can override this in terraform.tfvars
}

