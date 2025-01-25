# Create security groups for ECS tasks for each environment
resource "aws_security_group" "ecs_tasks_sg" {
  for_each = local.environments

  name        = "${local.base_name}-ecs-tasks-${each.value.name}"
  description = "Allow inbound traffic from ALB only on port 8000 for ${each.value.name}"
  vpc_id      = data.aws_vpc.default.id

  # Inbound rule to allow traffic only from ALB on port 8000
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg[each.key].id] # Only allow traffic from ALB security group
  }

  # Outbound rule to allow all traffic to any destination
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.base_name}-ecs-tasks-${each.value.name}"
    Environment = each.value.name
    Project     = local.base_name
  }
}

# Create security groups for ALB for each environment
resource "aws_security_group" "alb_sg" {
  for_each = local.environments

  name        = "${local.base_name}-alb-${each.value.name}"
  description = "Security group for ALB in ${each.value.name}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.base_name}-alb-${each.value.name}"
    Environment = each.value.name
    Project     = local.base_name
  }
}
