variable "buckets" {
  type = list(object({
    name   = string
    region = string

    create_user          = optional(bool, true)
    password_store_paths = optional(list(string))

    versioning = optional(object({
      enabled           = optional(bool, false)
      exclude_folders   = optional(bool, false)
      excluded_prefixes = optional(list(string), [])
    }), {})

    replication = optional(object({
      mode                        = string
      enabled                     = optional(bool, true)
      user_name                   = optional(string)
      site_a_endpoint             = optional(string)
      site_b_endpoint             = optional(string)
      region_site_b               = optional(string)
      bandwidth_limit             = optional(string, "100M")
      delete_marker_replication   = optional(bool, true)
      delete_replication          = optional(bool, true)
      existing_object_replication = optional(bool, true)
      metadata_sync               = optional(bool, true)
      prefix                      = optional(string)
      priority                    = optional(number, 1)
      tags                        = optional(map(string))
      }), {
      mode = ""
    })

    lifecycle_rules = optional(list(object({
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
    })), [])
  }))
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
