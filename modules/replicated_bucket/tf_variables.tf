variable "bucket_name" {
  type        = string
  description = "Specifies the name of the bucket to be created in the replication source and replication target"

  validation {
    condition     = length(var.bucket_name) >= 3
    error_message = "Bucket name too short."
  }
}

variable "target_host" {
  type        = string
  description = "Specifies the target host where data will be replicated"

  validation {
    condition     = can(regex("^https?://.*", var.target_host))
    error_message = "Target host must start with either 'http://' or 'https://'."
  }
}

variable "bandwidth_limit" {
  type        = string
  default     = "100M"
  description = "Specifies the maximum bandwidth allowed for replication"

  validation {
    condition     = can(regex("^\\d+[KMG]$", var.bandwidth_limit))
    error_message = "Bandwidth limit must start with a number and end with a unit (e.g., '100M')."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "replication_delete_marker_replication" {
  default = true
  type    = bool
}

variable "replication_delete_replication" {
  default = true
  type    = bool
}

variable "replication_enabled" {
  default = true
  type    = bool
}

variable "replication_existing_object_replication" {
  default = true
  type    = bool
}

variable "replication_metadata_sync" {
  default = true
  type    = bool
}

variable "replication_prefix" {
  default = null
  type    = string
}

variable "replication_priority" {
  default = 1
  type    = number

  validation {
    condition     = var.replication_priority >= 1
    error_message = "Replication priority must be at least 1."
  }
}

variable "replication_tags" {
  default = {}
  type    = map(string)
}

variable "force_destroy" {
  default = false
  type    = bool
}
