variable "bucket_name" {
  type        = string
  description = "Specifies the name of the bucket to be created in the replication source and replication target"

  validation {
    condition     = length(var.bucket_name) >= 3
    error_message = "Bucket name too short."
  }
}

variable "versioning" {
  type = object({
    enabled           = optional(bool, false)
    exclude_folders   = optional(bool, false)
    excluded_prefixes = optional(list(string), [])
  })

  default = {
    enabled = false
  }
}

variable "repliaction" {

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
      days           = number
      storage_class  = string
      newer_versions = optional(number, null)
    })), [])
  }))
  default = []
}

variable "replication_mode" {
  type    = string
  default = ""
  validation {
    condition     = contains(["", local.replication_mode_one_way, local.replication_mode_two_way], var.replication_mode)
    error_message = "Must be either \"\", \"${local.replication_mode_one_way}\" or \"${local.replication_mode_two_way}\"."
  }
}

# Service account for Site A -> Site B replication
variable "replication_user_name" {
  type    = string
  default = ""
}

# Site B -> Site A Replication
variable "site_a_endpoint" {
  type        = string
  default     = ""
  description = "In a single way replication, this variable specifies the host where data will be replicated"

  validation {
    condition     = var.site_a_endpoint == "" || can(regex("^https?://.*", var.site_a_endpoint))
    error_message = "Target host must be empty or start with either 'http://' or 'https://'."
  }
}

variable "site_b_endpoint" {
  type        = string
  default     = ""
  description = "In a two way replication, this variable specifies the host where data will be replicated from host a"

  validation {
    condition     = var.site_b_endpoint == "" || can(regex("^https?://.*", var.site_b_endpoint))
    error_message = "Target host must be empty or start with either 'http://' or 'https://'."
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

variable "region_site_a" {
  type    = string
  default = "us-east-1"
}

variable "region_site_b" {
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
