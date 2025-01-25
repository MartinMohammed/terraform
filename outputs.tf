# Output the default VPC ID
output "default_vpc_id" {
  description = "ID of the default VPC"
  value       = data.aws_vpc.default.id
}

# Output the subnet details to verify
output "selected_subnet_details" {
  description = "Details of the selected subnet"
  value       = data.aws_subnet.selected_subnet
}


# Output the subnet ID
output "selected_subnet_cidr" {
  description = "The ID of the selected subnet"
  value       = data.aws_subnet.selected_subnet.cidr_block
}


output "ecr_repository_url" {
  description = "The URL of the ECR repository for pulling the container image"
  value       = aws_ecr_repository.ElasticContainerRegistry.repository_url
}

output "ecs_cluster_names" {
  description = "The names of the ECS clusters"
  value = {
    for env in keys(local.environments) : env => aws_ecs_cluster.ecs_clusters[env].name
  }
}

output "ecs_service_names" {
  description = "The names of the ECS services"
  value = {
    for env in keys(local.environments) : env => aws_ecs_service.fastapi_ecs_service[env].name
  }
}

output "ecs_task_families" {
  description = "The family names of the ECS task definitions"
  value = {
    for env in keys(local.environments) : env => aws_ecs_task_definition.fargate_task[env].family
  }
}

output "ecs_task_definition_arns" {
  description = "The ARNs of the ECS task definitions"
  value = {
    for env in keys(local.environments) : env => aws_ecs_task_definition.fargate_task[env].arn
  }
}


output "ecs_security_group_id" {
  description = "The security group ID used by the ECS tasks"
  value       = aws_security_group.ecs_tasks_sg.id
}

output "alb_dns_names" {
  description = "The DNS names of the ALBs"
  value = {
    for env in keys(local.environments) : env => aws_lb.ecs_alb[env].dns_name
  }
}
