resource "aws_ecr_repository" "this" {
  name = var.name

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = var.tags
}
resource "aws_ecr_lifecycle_policy" "hello_python" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last 30 tagged images"
        selection = {
          tagStatus      = "tagged"
          countType      = "imageCountMoreThan"
          countNumber    = 30
          tagPatternList = ["*"]
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
