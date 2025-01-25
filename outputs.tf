# Network outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "IDs of the subnets used"
  value       = data.aws_subnet.selected_subnet.id
}

# ECR outputs
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_repository.repository_url
}

output "ecr_repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.app_repository.name
}

# ECS outputs
output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_service_names" {
  description = "The names of the ECS services"
  value = {
    for env in keys(local.environments) : env => aws_ecs_service.fastapi_ecs_service[env].name
  }
}

output "ecs_task_definition_families" {
  description = "The family names of the ECS task definitions"
  value = {
    for env in keys(local.environments) : env => aws_ecs_task_definition.fargate_task[env].family
  }
}

output "ecs_task_definition_revisions" {
  description = "The revisions of the ECS task definitions"
  value = {
    for env in keys(local.environments) : env => aws_ecs_task_definition.fargate_task[env].revision
  }
}

# Load Balancer outputs
output "alb_dns_names" {
  description = "The DNS names of the load balancers"
  value = {
    for env in keys(local.environments) : env => aws_lb.ecs_alb[env].dns_name
  }
}

output "alb_zone_ids" {
  description = "The zone IDs of the load balancers"
  value = {
    for env in keys(local.environments) : env => aws_lb.ecs_alb[env].zone_id
  }
}

# Environment info
output "environments" {
  description = "Environment configurations"
  value = {
    for env in keys(local.environments) : env => {
      name          = local.environments[env].name
      desired_count = local.environments[env].desired_count
      cpu           = local.environments[env].cpu
      memory        = local.environments[env].memory
    }
  }
}

output "resource_settings" {
  description = "Current environment resource settings"
  value       = var.resource_settings
}
