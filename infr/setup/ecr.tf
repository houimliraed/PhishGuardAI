
# ecr repos

resource "aws_ecr_repository" "devopsml_backend" {
  name                 = "devopsml-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
resource "aws_ecr_repository" "devopsml_frontend" {
  name                 = "devopsml-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

