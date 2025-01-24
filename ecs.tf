resource "aws_ecs_cluster" "ECS_Cluster" {
  name = "fastapi-ecs-cluster"
  setting {
    name  = "containerInsights" # For CloudWatch Container Insights
    value = "enabled"
  }
}


resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_strategy" {
  cluster_name = aws_ecs_cluster.ECS_Cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100 # Prefer Fargate Spot as much as possible
    capacity_provider = "FARGATE_SPOT"
  }
  # Fallback to Fargate when Fargate Spot is unavailable
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0 # No tasks are required to run on Fargate
    weight            = 1 # Lower weight for fallback to Fargate
  }

}


resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "fastapi-service"
  network_mode             = "awsvpc"                                 # Required for Fargate
  requires_compatibilities = ["FARGATE"]                              # Specify Fargate service
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # Execution role for pulling image and logging
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn # Task role for permissions needed by the app
  cpu                      = "512"                                    # 512 vCPU units
  memory                   = "1024"                                   # 1GB of memory

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  # Container definition using ECR image
  container_definitions = jsonencode([
    {
      name  = "fastapi-service"
      image = "${aws_ecr_repository.backend.repository_url}:latest" # Using the latest image from ECR

      # Environment variables can be empty if not needed
      environment = [],

      # Port mappings for your application
      portMappings = [
        {
          containerPort = 8000 # Port your application listens to inside the container
          hostPort      = 8000
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      # Log configuration using AWS CloudWatch Logs
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/fastapi-service"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
          mode                  = "non-blocking"
        }
      }

      essential = true # Ensure the container is marked as essential
    }
  ])
}
