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
# LIFECYCLE POLICIES
# -------------------------------


resource "aws_ecr_lifecycle_policy" "this" {
  for_each = {
    for repo_name, repo_cfg in var.repositories :
    repo_name => repo_cfg
    if try(repo_cfg.lifecycle_policy, null) != null
  }

  repository = each.key

  policy = jsonencode({
    rules = each.value.lifecycle_policy.rules
  })

  region = var.region
}
