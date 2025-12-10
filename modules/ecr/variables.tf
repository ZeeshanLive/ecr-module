variable "repositories" {
  description = "Map of ECR repositories to create"
  type = map(object({
    image_tag_mutability = optional(string, "IMMUTABLE")

    encryption_configuration = object({
      encryptionType = string
      kmsKeyId       = optional(string)
    })

    image_scanning_configuration = object({
      scanOnPush = bool
    })

    lifecycle_policy = optional(object({
      rules = optional(list(object({
        rulePriority = number
        description  = optional(string)

        selection = object({
          tagStatus       = string
          tagPatternList  = optional(list(string))
          tagPrefixList   = optional(list(string))
          countType       = string
          countUnit       = optional(string)
          countNumber     = optional(number)
        })

        action = object({
          type               = string
          targetStorageClass = optional(string)
        })
      })), [])
    }), null)
  }))
}
