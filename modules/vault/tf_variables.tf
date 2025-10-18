variable "access_keys" {
  type = object({
    name           = string
    host_nice_name = string
    access_key     = string
    secret_key     = string
  })

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.access_keys.name))
    error_message = "name may only contain lowercase letters, numbers and hyphens (-)."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.access_keys.host_nice_name))
    error_message = "host_nicename may only contain lowercase letters, numbers and hyphens (-)."
  }
}

variable "password_store_paths" {
  type        = list(string)
  description = "Paths to write the secret to."

  validation {
    condition = alltrue([
      for path in var.password_store_paths : length(path) >= 5
    ])
    error_message = "Each path in password_store_paths must be at least 5 characters long."
  }

  validation {
    condition = alltrue([
      for path in var.password_store_paths :
      !startswith(path, "/") && !endswith(path, "/")
    ])
    error_message = "Each path in password_store_paths must not start or end with a slash ('/')."
  }

  validation {
    condition = alltrue([
      for path in var.password_store_paths : length(regexall("%s", path)) == 2
      ])
    error_message = "Each path must contain exactly two occurrences of '%s'."
  }
}

variable "vault_kv2_mount" {
  type    = string
  default = "secret"

  validation {
    condition     = !endswith(var.vault_kv2_mount, "/") && length(var.vault_kv2_mount) > 3
    error_message = "vault_kv2_mount should not end with a slash."
  }
}

variable "metadata" {
  type        = map(any)
  default     = null
  description = "Optional metadata to attach to the secret."
}
