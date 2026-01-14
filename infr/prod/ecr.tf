# ECR Repositories - Already exist, just reference them

data "aws_ecr_repository" "backend" {
  name = "devopsml-backend"
}

data "aws_ecr_repository" "frontend" {
  name = "devopsml-frontend"
}

output "backend_repository_url" {
  value = data.aws_ecr_repository.backend.repository_url
}

output "frontend_repository_url" {
  value = data.aws_ecr_repository.frontend.repository_url
}
