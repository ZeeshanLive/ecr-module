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
    for name, repo in var.repositories :
    name => repo if repo.lifecycle_policy != null
  }

  repository = each.key
  policy     = jsonencode({
    rules = each.value.lifecycle_policy.rules
  })

  region = var.region
}

