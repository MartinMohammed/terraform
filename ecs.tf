locals {
  base_name = var.base_name # This should be defined in variables.tf
  environments = {
    dev = {
      name          = "dev"
      desired_count = 1
      cpu           = "512"
      memory        = "1024"
    }
    prod = {
      name          = "prod"
      desired_count = 2
      cpu           = "1024"
      memory        = "2048"
    }
  }
}

# Create ECS clusters for dev and prod
resource "aws_ecs_cluster" "ecs_clusters" {
  for_each = local.environments

  name = "${local.base_name}-cluster-${each.key}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Create capacity providers for each cluster
resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_strategy" {
  for_each = local.environments

  cluster_name = aws_ecs_cluster.ecs_clusters[each.key].name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 1
  }
}

# Create task definitions for each environment
resource "aws_ecs_task_definition" "fargate_task" {
  for_each = local.environments

  family                   = "${local.base_name}-service-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name  = "${local.base_name}-service-${each.key}"
      image = "${aws_ecr_repository.ElasticContainerRegistry.repository_url}:${each.key}"

      secrets = [
        {
          name      = "MISTRAL_API_KEY",
          valueFrom = aws_secretsmanager_secret.mistral_api_key.arn
        }
      ],

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.base_name}-service-${each.key}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
          mode                  = "non-blocking"
        }
      }

      essential = true
    }
  ])
}

# Create ALB for each environment
resource "aws_lb" "ecs_alb" {
  for_each = local.environments

  name               = "${local.base_name}-alb-${each.key}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default_subnets.ids
}

# Create target groups for each environment
resource "aws_lb_target_group" "ecs_tg" {
  for_each = local.environments

  name        = "${local.base_name}-tg-${each.key}"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  stickiness {
    type            = "app_cookie"
    cookie_name     = "session_id"
    cookie_duration = 86400
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

# Create listeners for each environment
resource "aws_lb_listener" "front_end" {
  for_each = local.environments

  load_balancer_arn = aws_lb.ecs_alb[each.key].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[each.key].arn
  }
}

# Create ECS services for each environment
resource "aws_ecs_service" "fastapi_ecs_service" {
  for_each = local.environments

  name            = "${local.base_name}-service-${each.key}"
  cluster         = aws_ecs_cluster.ecs_clusters[each.key].id
  task_definition = aws_ecs_task_definition.fargate_task[each.key].arn
  desired_count   = each.value.desired_count

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
    target_group_arn = aws_lb_target_group.ecs_tg[each.key].arn
    container_name   = "${local.base_name}-service-${each.key}"
    container_port   = 8000
  }
}
