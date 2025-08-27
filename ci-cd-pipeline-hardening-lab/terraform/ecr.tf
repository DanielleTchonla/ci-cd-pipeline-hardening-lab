resource "aws_ecr_repository" "flask_cicd" {
  name                 = "flask-cicd"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
