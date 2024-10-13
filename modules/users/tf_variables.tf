variable "bucket_name" {
  type = string

  validation {
    condition     = length(var.bucket_name) >= 3
    error_message = "Bucket name too short."
  }
}

variable "user_name" {
  type = string

  validation {
    condition     = length(var.user_name) >= 3
    error_message = "User name too short."
  }
}

variable "directory_name" {
  type    = string
  default = null
}

variable "password_store_paths" {
  type        = list(string)
  description = "Paths to write the credentials to."
}
