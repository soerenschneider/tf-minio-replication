variable "minio_source_user" {
  type = string
}

variable "minio_source_password" {
  type = string
}

variable "minio_target_host" {
  type = string
}

variable "minio_target_user" {
  type = string
}

variable "minio_target_password" {
  type = string
}

variable "buckets" {
  type = list(object({
    name = string

    versioning = object({
      enabled           = optional(bool, false)
      exclude_folders   = optional(bool, false)
      excluded_prefixes = optional(list(string), [])
    })

    replication = object({
      mode = string
      site_a_endpoint       = string
      site_b_endpoint       = string
    })

    lifecycle_rules = object({
      id      = string
      enabled = optional(bool, true)
      prefix  = optional(string, "")
      tags    = optional(map(string), {})

      # Expiration settings
      expiration_days              = optional(number, null)
      expiration_date              = optional(string, null)
      expired_object_delete_marker = optional(bool, false)

      # Non-current version expiration
      noncurrent_expirations = optional(list(object({
        days           = number
        newer_versions = optional(number, null)
      })), [])

      # Transition settings
      transitions = optional(list(object({
        days          = optional(number, null)
        date          = optional(string, null)
        storage_class = string
      })), [])

      # Non-current version transitions
      noncurrent_transitions = optional(list(object({
        days           = number # needed format "Nd"
        storage_class  = string
        newer_versions = optional(number, null)
    })), [])

    })
  }))
  default = []
}

variable "users" {
  type = list(object({
    name                 = string,
    directory            = optional(string)
    password_store_paths = optional(list(string))
  }))
}

variable "password_store_paths" {
  type        = list(string)
  default     = []
  description = "Password storage path"
}
