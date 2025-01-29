variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "prod"
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


# ------------------- WAF variables -------------------
variable "waf_web_acl_name" {
  description = "The name of the WAF web ACL"
  default     = "game-jam-waf"
}

variable "waf_web_acl_description" {
  description = "The description of the WAF web ACL"
  default     = "WAF ACL for Game Jam application"
}

variable "rule_name" {
  description = "The name of the WAF rule"
  default     = "bad-bot-rule"
}
variable "rule_priority" {
  description = "The priority of the WAF rule"
  default     = 1
}

# ------------------- Environment specific variables -------------------
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
      # Single smaller instance
      instance_count   = 1
      instance_type    = "t3.micro" # 2 vCPUs, 1GB RAM
      container_memory = 512        # 0.5GB memory for the container
      container_cpu    = 256        # 0.25 vCPU (in ECS CPU units)
    }
  }
}

