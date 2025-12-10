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
# -------------------------------
# LIFECYCLE POLICIES (Optional)
# -------------------------------
# -------------------------------
# LIFECYCLE POLICIES (Optional)
# -------------------------------
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = {
    for repo_name, repo_cfg in local.repos :
    repo_name => repo_cfg
    if can(repo_cfg.lifecycle_policy.rules) && length(repo_cfg.lifecycle_policy.rules) > 0
  }

  repository = each.key
  region     = var.region

  # Use jsonencode with compact option to avoid null values
  policy = jsonencode({
    rules = [
      for rule in each.value.lifecycle_policy.rules : {
        rulePriority = rule.rulePriority
        description  = lookup(rule, "description", null)
        selection = {
          tagStatus     = rule.selection.tagStatus
          tagPrefixList = lookup(rule.selection, "tagPrefixList", null)
          tagPatternList = lookup(rule.selection, "tagPatternList", null)
          countType     = rule.selection.countType
          countUnit     = lookup(rule.selection, "countUnit", null)
          countNumber   = lookup(rule.selection, "countNumber", null)
        }
        action = {
          type = rule.action.type
          targetStorageClass = lookup(rule.action, "targetStorageClass", null)
        }
      }
    ]
  })
}
