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
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.app_service.name
}

output "ecs_task_definition_family" {
  description = "The family name of the ECS task definition"
  value       = aws_ecs_task_definition.app_task.family
}

output "ecs_task_definition_revision" {
  description = "The revision of the ECS task definition"
  value       = aws_ecs_task_definition.app_task.revision
}

# Load Balancer outputs
output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

# Environment info
output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "resource_settings" {
  description = "Current environment resource settings"
  value       = local.env_settings
}
