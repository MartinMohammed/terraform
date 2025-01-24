resource "aws_ecr_repository" "ElasticContainerRegistry" {
  name                 = "ecr-fastapi-service"
  image_tag_mutability = "MUTABLE" # if the same tag is pushed again, it will be overwritten

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR Lifecycle policy to keep only last 5 images
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}
