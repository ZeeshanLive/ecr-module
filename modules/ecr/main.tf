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

resource "aws_ecr_repository" "this" {
  for_each = local.repos

  name                 = each.key
  image_tag_mutability = lookup(each.value, "image_tag_mutability", "IMMUTABLE")

  encryption_configuration {
    encryption_type = each.value.encryption_configuration.encryptionType
    # kms_key = each.value.encryption_configuration.kmsKeyId
  }

  image_scanning_configuration {
    scan_on_push = each.value.image_scanning_configuration.scanOnPush
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = {
    for k, v in var.repository :
    k => v
    if try(v.lifecycle_policy.rules, null) != null
  }

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = try(each.value.lifecycle_policy.rules, [])
  })
}
