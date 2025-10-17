resource "minio_s3_bucket" "bucket_in_a" {
  bucket = var.bucket_name
}

resource "minio_s3_bucket_versioning" "bucket_in_a" {
  count = var.versioning.enabled ? 1 : 0

  bucket = minio_s3_bucket.bucket_in_a.bucket

  versioning_configuration {
    status            = "Enabled"
    exclude_folders   = var.versioning.exclude_folders
    excluded_prefixes = var.versioning.excluded_prefixes
  }
}

resource "minio_s3_bucket" "bucket_in_b" {
  count = var.replication_mode != "" ? 1 : 0

  provider = minio.deployment_b
  bucket   = var.bucket_name
}

resource "minio_s3_bucket_versioning" "bucket_in_b" {
  count = var.replication_mode != "" && var.versioning.enabled ? 1 : 0

  provider = minio.deployment_b
  bucket   = minio_s3_bucket.bucket_in_b[0].bucket

  versioning_configuration {
    status            = "Enabled"
    exclude_folders   = var.versioning.exclude_folders
    excluded_prefixes = var.versioning.excluded_prefixes
  }
}

resource "minio_ilm_policy" "ilm_policy_bucket_a" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = minio_s3_bucket.bucket_in_a.bucket

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id         = rule.value.id
      status     = rule.value.enabled ? "Enabled" : "Disabled"
      filter     = rule.value.prefix
      expiration = rule.value.expiration_days

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days != null ? format("%dd", transition.value.days) : null
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_transition" {
        for_each = rule.value.noncurrent_transitions

        content {
          days           = noncurrent_transition.value.days != null ? format("%dd", noncurrent_transition.value.days) : null
          storage_class  = noncurrent_transition.value.storage_class
          newer_versions = noncurrent_transition.value.newer_versions
        }
      }

      dynamic "noncurrent_expiration" {
        for_each = rule.value.noncurrent_expirations

        content {
          days           = noncurrent_expiration.value.days != null ? format("%dd", noncurrent_expiration.value.days) : null
          newer_versions = noncurrent_expiration.value.newer_versions
        }
      }
    }
  }
}

resource "minio_ilm_policy" "ilm_policy_bucket_b" {
  count = length(var.lifecycle_rules) > 0 && var.replication_mode != "" ? 1 : 0

  provider = minio.deployment_b
  bucket   = minio_s3_bucket.bucket_in_b[0].bucket

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id         = rule.value.id
      status     = rule.value.enabled ? "Enabled" : "Disabled"
      filter     = rule.value.prefix
      expiration = rule.value.expiration_days

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days != null ? format("%dd", transition.value.days) : null
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_transition" {
        for_each = rule.value.noncurrent_transitions

        content {
          days           = noncurrent_transition.value.days != null ? format("%dd", noncurrent_transition.value.days) : null
          storage_class  = noncurrent_transition.value.storage_class
          newer_versions = noncurrent_transition.value.newer_versions
        }
      }

      dynamic "noncurrent_expiration" {
        for_each = rule.value.noncurrent_expirations

        content {
          days           = noncurrent_expiration.value.days != null ? format("%dd", noncurrent_expiration.value.days) : null
          newer_versions = noncurrent_expiration.value.newer_versions
        }
      }
    }
  }
}
