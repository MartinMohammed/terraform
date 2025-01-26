variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'"
  }
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
  description = "Base name for all resources"
  type        = string
  default     = "game-jam"
}

# Environment specific variables
variable "resource_settings" {
  description = "Environment specific resource settings"
  type = map(object({
    instance_count   = number
    instance_type    = string
    container_memory = number
    container_cpu    = number
  }))
  default = {
    # Dev environment commented out as we're focusing on production
    # dev = {
    #   instance_count   = 1
    #   instance_type    = "t3.micro"
    #   container_memory = 512
    #   container_cpu    = 256
    # }
    prod = {
      # Single instance with enough capacity for 50 concurrent users
      # 4GB memory and 2 vCPU should comfortably handle 50 concurrent users
      instance_count   = 1
      instance_type    = "t3.micro" # Smaller instance type (though not used in Fargate)
      container_memory = 2048       # 2GB memory
      container_cpu    = 1024       # 1 vCPU
    }
  }
}

