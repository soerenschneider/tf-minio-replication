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

variable "bucket_name" {
  type = string
}

variable "lifecycle_rules" {
  type = list(object({
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

    # Abort incomplete multipart uploads
    abort_incomplete_multipart_upload_days = optional(number, null)
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
