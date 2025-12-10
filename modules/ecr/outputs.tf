# Add to main.tf for debugging
output "debug_lifecycle_policies" {
  value = {
    for repo_name, repo_cfg in local.repos :
    repo_name => {
      has_lifecycle_policy = try(repo_cfg.lifecycle_policy, null) != null
      has_rules = try(length(repo_cfg.lifecycle_policy.rules), 0) > 0
      rule_count = try(length(repo_cfg.lifecycle_policy.rules), 0)
    }
  }
}
