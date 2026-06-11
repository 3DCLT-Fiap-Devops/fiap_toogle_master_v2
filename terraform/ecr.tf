locals {
  services = ["analytics-service", "auth-service", "evaluation-service", "flag-service", "targeting-service"]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.services)

  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = var.project_name
  }
}
