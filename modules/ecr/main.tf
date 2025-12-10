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
  repositories = var.repositories
}

resource "aws_ecr_repository" "this" {
  for_each = local.repositories

  name                 = each.key
  image_tag_mutability = lookup(each.value, "image_tag_mutability", "IMMUTABLE")

  encryption_configuration {
    encryption_type = lookup(each.value.encryption_configuration, "encryptionType", "AES256")
  }

  image_scanning_configuration {
    scan_on_push = lookup(each.value.image_scanning_configuration, "scanOnPush", false)
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = {
    for key, repo in local.repositories :
    key => repo
    if lookup(repo, "lifecycle_policy", null) != null
  }

  repository = each.key

  policy = templatefile("${path.module}/lifecycle.tpl.json", {
    rules = each.value.lifecycle_policy.rules
  })
}
