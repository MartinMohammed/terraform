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
      image = "${aws_ecr_repository.ElasticContainerRegistry.repository_url}:latest" # Using the latest image from ECR

      # Environment variables including the secret
      secrets = [
        {
          name      = "MISTRAL_API_KEY",
          valueFrom = aws_secretsmanager_secret.mistral_api_key.arn
        }
      ],

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

resource "aws_lb" "ecs_alb" {
  name               = "fastapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default_subnets.ids
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "fastapi-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  # Enable sticky sessions using application-based cookies
  stickiness {
    type            = "app_cookie"
    cookie_name     = "session_id" # This should match your FastAPI session cookie name
    cookie_duration = 86400        # 24 hours in seconds
  }

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}


resource "aws_ecs_service" "fastapi_ecs_service" {
  name            = "fastapi-service"
  cluster         = aws_ecs_cluster.ECS_Cluster.id
  task_definition = aws_ecs_task_definition.fargate_task.arn
  desired_count   = 1

  # Capacity Provider Strategy: Prefer Fargate Spot, fallback to Fargate
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }

  network_configuration {
    subnets          = data.aws_subnets.default_subnets.ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "fastapi-service"
    container_port   = 8000
  }
}
