
# Define the environments configuration globally
# Locals defined in any .tf file will be available to all other .tf files
# locals allow us to group several variables together. They are evaluated at runtime.
locals {
  base_name = var.base_name
  environments = {
    prod = {
      name          = var.environment_names["prod"]
      desired_count = var.resource_settings["prod"].instance_count
      cpu           = var.resource_settings["prod"].container_cpu
      memory        = var.resource_settings["prod"].container_memory
    }
  }

  # Resource naming patterns
  resource_names = {
    cluster = "${local.base_name}-cluster"
    service = "app-service"
    task    = "${local.base_name}-task"
    alb     = "${local.base_name}-alb"
    tg      = "${local.base_name}-tg"
  }
}
