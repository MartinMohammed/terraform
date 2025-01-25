# Create ECR repositories for each environment
resource "aws_ecr_repository" "app_repository" {
  for_each = local.environments

  name                 = "${local.base_name}-${each.value.name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Environment = each.value.name
    Project     = local.base_name
  }
}

