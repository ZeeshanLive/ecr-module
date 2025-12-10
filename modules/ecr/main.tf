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
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = {
    for name, cfg in local.repos :
    name => cfg.lifecycle_policy
    if try(cfg.lifecycle_policy, null) != null && try(length(cfg.lifecycle_policy.rules), 0) > 0
  }

  repository = each.key

  policy = jsonencode({
    rules = [
      for rule in each.value.rules : {
        # Build rule dynamically, only including non-null fields
        for key, value in {
          rulePriority = rule.rulePriority
          description  = lookup(rule, "description", null) != null ? rule.description : null
          selection = {
            for skey, svalue in {
              tagStatus     = rule.selection.tagStatus
              tagPrefixList = lookup(rule.selection, "tagPrefixList", null)
              tagPatternList = lookup(rule.selection, "tagPatternList", null)
              countType     = rule.selection.countType
              countUnit     = lookup(rule.selection, "countUnit", null)
              countNumber   = lookup(rule.selection, "countNumber", null)
            } : skey => svalue if svalue != null
          }
          action = {
            for akey, avalue in {
              type               = rule.action.type
              targetStorageClass = lookup(rule.action, "targetStorageClass", null)
            } : akey => avalue if avalue != null
          }
        } : key => value if value != null
      }
    ]
  })
}
