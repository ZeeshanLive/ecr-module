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

    lifecycle_policy = optional(string, null)  # Now a string path to JSON file
  }))
}
