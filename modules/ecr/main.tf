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
    for name, cfg in local.repos :
    name => cfg.lifecycle_policy
    if try(cfg.lifecycle_policy, null) != null && try(length(cfg.lifecycle_policy.rules), 0) > 0
  }

  repository = each.key

  policy = jsonencode({
    rules = each.value.rules
  })
}


resource "null_resource" "debug" {
  for_each = {
    for name, cfg in local.repos :
    name => cfg.lifecycle_policy
    if try(cfg.lifecycle_policy, null) != null && try(length(cfg.lifecycle_policy.rules), 0) > 0
  }

  triggers = {
    policy_json = jsonencode(each.value)
  }

  provisioner "local-exec" {
    command = "echo 'Policy for ${each.key}: ${jsonencode(each.value)}'"
  }
}
