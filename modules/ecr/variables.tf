# modules/ecr/variables.tf - Input variables
variable "ecr_repositories" {
  description = "Map of ECR repository configurations from YAML export"
  type = map(object({
    repositoryName              = string
    repositoryArn               = optional(string)
    registryId                  = optional(string)
    createdAt                   = optional(string)
    imageTagMutability          = optional(string, "MUTABLE")
    imageScanningConfiguration = optional(object({
      scanOnPush = optional(bool, true)
    }), {})
    encryptionConfiguration = optional(object({
      encryptionType = optional(string, "AES256")
    }), {})
    tags = optional(list(object({
      key   = string
      value = string
    })), [])
    lifecyclePolicy = optional(object({
      lifecyclePolicyText = optional(string)
    }), {})
    repositoryPolicy = optional(object({
      policyText = optional(string)
    }), {})
  }))
  default = {}
}

variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_lifecycle_policies" {
  description = "Enable ECR lifecycle policies"
  type        = bool
  default     = true
}

variable "enable_repository_policies" {
  description = "Enable ECR repository policies"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption for ECR repositories"
  type        = bool
  default     = true
}

variable "enable_scan_on_push" {
  description = "Enable scan on push for ECR repositories"
  type        = bool
  default     = true
}

variable "create_pull_through_cache_rules" {
  description = "Create pull through cache rules"
  type        = bool
  default     = false
}

variable "pull_through_cache_rules" {
  description = "Map of pull through cache rules"
  type        = map(string)
  default     = {}
}
