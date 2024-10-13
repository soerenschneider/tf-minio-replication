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
