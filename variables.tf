variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "environment_names" {
  description = "Map of environment names"
  type        = map(string)
  default = {
    dev  = "dev"
    prod = "prod"
  }
}

variable "base_name" {
  description = "Base name for all resources (e.g., 'fastapi' or 'game-jam')"
  type        = string
  default     = "fastapi" # You can override this in terraform.tfvars
}

