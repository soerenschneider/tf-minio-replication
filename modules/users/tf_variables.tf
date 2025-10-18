variable "users" {
  type = object({
    user_name = string
    buckets = map(object({
      read_paths = optional(list(string), ["/"])
      write_paths = optional(list(string), ["/"])
    }))
  })
}

variable "bucket_name" {
  description = "Name of the bucket to grant access to. Must be a specific bucket, not '*'."
  type        = string

  validation {
    condition = alltrue([
      length(var.bucket_name) > 2,
      length(var.bucket_name) <= 63,
      can(regex("^[a-z0-9][a-z0-9\\-\\.]*[a-z0-9]$", var.bucket_name)),
      !contains([var.bucket_name], "*") # disallow wildcard
    ])
    error_message = <<EOT
bucket_name must be a valid bucket name:
- 3 to 63 characters
- lowercase letters, numbers, dots, and hyphens only
- cannot start or end with a hyphen or dot
- cannot be '*'
EOT
  }
}

variable "user_name" {
  description = "Username for the IAM user"
  type        = string
}

variable "read_paths" {
  description = "List of paths the user can read from. Use '/' for full bucket access."
  type        = list(string)
  default     = ["/"]

  validation {
    condition = alltrue([
      for path in var.read_paths : can(regex("^/", path))
    ])
    error_message = "All paths must start with '/', e.g., '/' for root or '/folder/subfolder'."
  }
}

variable "write_paths" {
  description = "List of paths the user can write to. Use '/' for full bucket access."
  type        = list(string)
  default     = ["/"]

  validation {
    condition = alltrue([
      for path in var.write_paths : can(regex("^/", path))
    ])
    error_message = "All paths must start with '/', e.g., '/' for root or '/folder/subfolder'."
  }
}

variable "force_destroy" {
  description = "Whether to force destroy user even if it has access keys"
  type        = bool
  default     = true
}

variable "password_store_paths" {
  type        = list(string)
  description = "Paths to write the credentials to."
}
