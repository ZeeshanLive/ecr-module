# modules/ecr/main.tf - Main Terraform module
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

# Create ECR repositories
resource "aws_ecr_repository" "this" {
  for_each = var.ecr_repositories
  
  name                 = each.key
  image_tag_mutability = try(each.value.imageTagMutability, "MUTABLE")
  
  image_scanning_configuration {
    scan_on_push = try(each.value.imageScanningConfiguration.scanOnPush, var.enable_scan_on_push)
  }
  
  encryption_configuration {
    encryption_type = try(each.value.encryptionConfiguration.encryptionType, 
                         var.enable_encryption ? "KMS" : "AES256")
  }
  
  tags = merge(var.default_tags, 
               { Name = each.key },
               { for tag in try(each.value.tags, []) : tag.key => tag.value })
}

# Apply lifecycle policies
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.enable_lifecycle_policies ? {
    for name, repo in var.ecr_repositories : 
    name => repo 
    if try(repo.lifecyclePolicy.lifecyclePolicyText, null) != null
  } : {}
  
  repository = aws_ecr_repository.this[each.key].name
  policy     = try(jsondecode(each.value.lifecyclePolicy.lifecyclePolicyText), 
                  each.value.lifecyclePolicy.lifecyclePolicyText)
  
  depends_on = [aws_ecr_repository.this]
}

# Apply repository policies
resource "aws_ecr_repository_policy" "this" {
  for_each = var.enable_repository_policies ? {
    for name, repo in var.ecr_repositories : 
    name => repo 
    if try(repo.repositoryPolicy.policyText, null) != null
  } : {}
  
  repository = aws_ecr_repository.this[each.key].name
  
  policy = try(jsondecode(each.value.repositoryPolicy.policyText), 
              each.value.repositoryPolicy.policyText)
  
  depends_on = [aws_ecr_repository.this]
}

# Output image pull/push URLs
resource "aws_ecr_repository_pull_through_cache_rule" "this" {
  for_each = var.create_pull_through_cache_rules ? var.pull_through_cache_rules : {}
  
  ecr_repository_prefix = each.key
  upstream_registry_url = each.value
}
