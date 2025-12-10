terraform {
  backend "local" {}
}

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  repos = var.repositories
}

# -------------------------------
# ECR REPOSITORIES
# -------------------------------
resource "aws_ecr_repository" "this" {
  for_each = local.repos

  name                 = each.key
  image_tag_mutability = lookup(each.value, "image_tag_mutability", "IMMUTABLE")

  encryption_configuration {
    encryption_type = each.value.encryption_configuration.encryptionType
  }

  image_scanning_configuration {
    scan_on_push = each.value.image_scanning_configuration.scanOnPush
  }
}

# -------------------------------
# LIFECYCLE POLICIES (Optional)
# -------------------------------
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = {
    for repo_name, repo_cfg in local.repos :
    repo_name => repo_cfg
    if contains(keys(repo_cfg), "lifecycle_policy") && repo_cfg.lifecycle_policy != null
  }

  repository = each.key
  region     = var.region

  # Safely encode rules, fallback to empty list just in case
  policy = jsonencode({
    rules = try(each.value.lifecycle_policy.rules, [])
  })
}
