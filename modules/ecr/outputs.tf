# modules/ecr/outputs.tf - Output values
output "repository_urls" {
  description = "Map of repository names to repository URLs"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to repository ARNs"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.arn
  }
}

output "repository_registry_ids" {
  description = "Map of repository names to registry IDs"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.registry_id
  }
}

output "lifecycle_policies" {
  description = "Map of repository names to lifecycle policy status"
  value = {
    for name, policy in aws_ecr_lifecycle_policy.this :
    name => {
      policy = policy.policy
    }
  }
  sensitive = true
}

output "repository_policies" {
  description = "Map of repository names to repository policy status"
  value = {
    for name, policy in aws_ecr_repository_policy.this :
    name => {
      policy = policy.policy
    }
  }
  sensitive = true
}

output "all_repositories" {
  description = "Complete information about all created repositories"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => {
      name                 = repo.name
      arn                  = repo.arn
      registry_id          = repo.registry_id
      repository_url       = repo.repository_url
      image_tag_mutability = repo.image_tag_mutability
      encryption_type      = repo.encryption_configuration[0].encryption_type
      scan_on_push         = repo.image_scanning_configuration[0].scan_on_push
      has_lifecycle_policy = contains(keys(aws_ecr_lifecycle_policy.this), name)
      has_repository_policy = contains(keys(aws_ecr_repository_policy.this), name)
    }
  }
}

output "export_summary" {
  description = "Summary of imported/created repositories"
  value = {
    total_repositories   = length(aws_ecr_repository.this)
    with_lifecycle_policy = length(aws_ecr_lifecycle_policy.this)
    with_repository_policy = length(aws_ecr_repository_policy.this)
    region               = var.region
  }
}
