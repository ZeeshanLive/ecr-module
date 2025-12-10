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
# In main.tf
# -------------------------------
# LIFECYCLE POLICIES (Optional) - SIMPLE VERSION
# -------------------------------
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = {
    for name, cfg in local.repos :
    name => cfg.lifecycle_policy
    if try(cfg.lifecycle_policy, null) != null && try(length(cfg.lifecycle_policy.rules), 0) > 0
  }

  repository = each.key

  # Build clean JSON without any nulls
  policy = jsonencode({
    rules = [
      for rule in each.value.rules : {
        # Required field
        rulePriority = rule.rulePriority
        # Build selection - VERY carefully
        selection = {
          tagStatus = rule.selection.tagStatus
          countType = rule.selection.countType
          # Only add these if they exist and are not null/empty
          tagPatternList = can(rule.selection.tagPatternList) && rule.selection.tagPatternList != null && length(rule.selection.tagPatternList) > 0 ? rule.selection.tagPatternList : null
          tagPrefixList = can(rule.selection.tagPrefixList) && rule.selection.tagPrefixList != null && length(rule.selection.tagPrefixList) > 0 ? rule.selection.tagPrefixList : null
          countUnit = can(rule.selection.countUnit) && rule.selection.countUnit != null && rule.selection.countUnit != "" ? rule.selection.countUnit : null
          countNumber = can(rule.selection.countNumber) && rule.selection.countNumber != null ? rule.selection.countNumber : null
        }
        # Build action
        action = {
          type = rule.action.type
          targetStorageClass = can(rule.action.targetStorageClass) && rule.action.targetStorageClass != null && rule.action.targetStorageClass != "" ? rule.action.targetStorageClass : null
        }
      }
    ]
  })

  # Post-process the JSON to remove nulls
  lifecycle {
    precondition {
      condition     = can(jsondecode(replace(replace(jsonencode({
        rules = [
          for rule in each.value.rules : {
            rulePriority = rule.rulePriority
            selection = {
              tagStatus = rule.selection.tagStatus
              countType = rule.selection.countType
              tagPatternList = can(rule.selection.tagPatternList) && rule.selection.tagPatternList != null && length(rule.selection.tagPatternList) > 0 ? rule.selection.tagPatternList : null
              tagPrefixList = can(rule.selection.tagPrefixList) && rule.selection.tagPrefixList != null && length(rule.selection.tagPrefixList) > 0 ? rule.selection.tagPrefixList : null
              countUnit = can(rule.selection.countUnit) && rule.selection.countUnit != null && rule.selection.countUnit != "" ? rule.selection.countUnit : null
              countNumber = can(rule.selection.countNumber) && rule.selection.countNumber != null ? rule.selection.countNumber : null
            }
            action = {
              type = rule.action.type
              targetStorageClass = can(rule.action.targetStorageClass) && rule.action.targetStorageClass != null && rule.action.targetStorageClass != "" ? rule.action.targetStorageClass : null
            }
          }
        ]
      }), ":null", ":null"), ":null,", ":null,")))
      error_message = "Generated JSON contains null values"
    }
  }
}
