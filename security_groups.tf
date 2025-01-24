resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-from-alb-sg"
  description = "Allow inbound traffic from ALB only on port 8000"
  vpc_id      = data.aws_vpc.default.id

  # Inbound rule to allow traffic only from ALB on port 8000
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only allow traffic from ALB security group
  }

  # Outbound rule to allow all traffic to any destination
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-tasks-from-alb-sg"
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "alb_security_group"
  description = "Security group for ALB"
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
}
