locals {
  base_name = var.base_name
  environments = {
    dev = {
      name          = var.environment_names["dev"]
      desired_count = var.resource_settings["dev"].instance_count
      cpu           = var.resource_settings["dev"].container_cpu
      memory        = var.resource_settings["dev"].container_memory
    }

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

# Create a single ECS cluster for both environments
resource "aws_ecs_cluster" "ecs_cluster" {
  name = local.resource_names.cluster

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Project = local.base_name
  }
}

# Create capacity providers for the cluster
resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_strategy" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

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

  family                   = "${local.resource_names.task}-${each.value.name}"
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
      name  = "${local.resource_names.service}-${each.value.name}"
      image = "${aws_ecr_repository.app_repository.repository_url}:${each.value.name}"

      secrets = [
        {
          name      = "MISTRAL_API_KEY"
          valueFrom = aws_secretsmanager_secret.mistral_api_key.arn
        },
        {
          name      = "ELEVEN_LABS_API_KEY"
          valueFrom = aws_secretsmanager_secret.eleven_labs_api_key.arn
        }
      ]

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
          awslogs-group         = "/ecs/${local.resource_names.service}-${each.value.name}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
          awslogs-create-group  = "true"
          mode                  = "non-blocking"
        }
      }

      essential = true

      environment = [
        {
          name  = "ENVIRONMENT"
          value = each.value.name
        }
      ]
    }
  ])

  tags = {
    Environment = each.value.name
    Project     = local.base_name
  }
}

# Create ALB for each environment
resource "aws_lb" "ecs_alb" {
  for_each = local.environments

  name               = "${local.resource_names.alb}-${each.value.name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg[each.key].id]
  subnets            = data.aws_subnets.default_subnets.ids

  tags = {
    Environment = each.value.name
    Project     = local.base_name
  }
}

# Create target groups for each environment
resource "aws_lb_target_group" "ecs_tg" {
  for_each = local.environments

  name        = "${local.resource_names.tg}-${each.value.name}"
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
    type = each.key == "prod" ? "redirect" : "forward"
    dynamic "redirect" {
      for_each = each.key == "prod" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    dynamic "forward" {
      for_each = each.key == "dev" ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.ecs_tg[each.key].arn
        }
      }
    }
  }
}

# HTTPS listener (only for prod)
resource "aws_lb_listener" "front_end_https" {
  # Only create for prod environment
  for_each = {
    for k, v in local.environments : k => v
    if k == "prod"
  }

  load_balancer_arn = aws_lb.ecs_alb[each.key].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg[each.key].arn
  }

  depends_on = [aws_acm_certificate_validation.cert_validation]
}

# Default certificate for dev environment
resource "aws_acm_certificate" "default_cert" {
  domain_name       = "*.${data.aws_caller_identity.current.account_id}.${var.aws_region}.elb.amazonaws.com"
  validation_method = "DNS"

  tags = {
    Environment = "dev"
    Project     = var.base_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create ECS services for each environment
resource "aws_ecs_service" "fastapi_ecs_service" {
  for_each = local.environments

  name            = "${local.resource_names.service}-${each.value.name}"
  cluster         = aws_ecs_cluster.ecs_cluster.id
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
    security_groups  = [aws_security_group.ecs_tasks_sg[each.key].id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg[each.key].arn
    container_name   = "${local.resource_names.service}-${each.value.name}"
    container_port   = 8000
  }

  tags = {
    Environment = each.value.name
    Project     = local.base_name
  }
}
