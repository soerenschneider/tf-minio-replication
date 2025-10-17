data "minio_iam_policy_document" "replication_policy" {
  count = var.replication.mode != "" ? 1 : 0

  statement {
    sid       = "ReadBuckets"
    effect    = "Allow"
    resources = ["arn:aws:s3:::*"]

    actions = [
      "s3:ListBucket",
    ]
  }

  statement {
    sid       = "EnableReplicationOnBucket"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.bucket_name}"]

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetEncryptionConfiguration",
    ]
  }

  statement {
    sid       = "EnableReplicatingDataIntoBucket"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ReplicateTags",
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:PutObject",
      "s3:PutObjectRetention",
      "s3:PutBucketObjectLockConfiguration",
      "s3:PutObjectLegalHold",
      "s3:DeleteObject",
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]
  }
}

# One-Way replication (A -> B)
resource "minio_iam_policy" "replication_in_b" {
  count = var.replication.mode != "" ? 1 : 0

  provider = minio.deployment_b

  name   = "bucket-replication-${var.bucket_name}"
  policy = data.minio_iam_policy_document.replication_policy[0].json
}

resource "minio_iam_user" "replication_in_b" {
  count = var.replication.mode != "" ? 1 : 0

  provider = minio.deployment_b

  name          = var.replication.user_name == "" ? "replication-${var.bucket_name}" : var.replication.user_name
  force_destroy = true
}

resource "minio_iam_user_policy_attachment" "replication_in_b" {
  count = var.replication.mode != "" ? 1 : 0

  provider = minio.deployment_b

  user_name   = minio_iam_user.replication_in_b[0].name
  policy_name = minio_iam_policy.replication_in_b[0].id
}

resource "minio_iam_service_account" "replication_in_b" {
  count = var.replication.mode != "" ? 1 : 0

  provider = minio.deployment_b

  target_user = minio_iam_user.replication_in_b[0].name

  depends_on = [
    minio_iam_user_policy_attachment.replication_in_b
  ]
}

resource "minio_s3_bucket_replication" "replication_in_b" {
  count = var.replication.mode != "" ? 1 : 0

  bucket = minio_s3_bucket.bucket_in_a.bucket

  rule {
    delete_marker_replication   = var.replication.delete_marker_replication
    delete_replication          = var.replication.delete_replication
    enabled                     = var.replication.enabled
    existing_object_replication = var.replication.existing_object_replication
    metadata_sync               = var.replication.metadata_sync
    prefix                      = var.replication.prefix
    priority                    = var.replication.priority
    tags                        = var.replication.tags

    target {
      bucket          = minio_s3_bucket.bucket_in_b[0].bucket
      secure          = startswith(var.replication.site_b_endpoint, "https://")
      host            = replace(replace(var.replication.site_b_endpoint, "https://", ""), "http://", "")
      bandwidth_limit = var.replication.bandwidth_limit
      region          = var.replication.region_site_b
      access_key      = minio_iam_service_account.replication_in_b[0].access_key
      secret_key      = minio_iam_service_account.replication_in_b[0].secret_key
    }
  }

  depends_on = [
    minio_s3_bucket_versioning.bucket_in_a,
    minio_s3_bucket_versioning.bucket_in_b
  ]

  lifecycle {
    precondition {
      condition     = var.replication.mode != local.replication_mode_two_way || var.replication.metadata_sync
      error_message = "replication_metadata_sync must be true when two_way_replication is enabled."
    }

    precondition {
      condition     = var.replication.mode != "" && var.replication.site_b_endpoint != ""
      error_message = "endpoint for site b must be set if replication_mode is set."
    }

    precondition {
      condition     = var.replication.mode != "" && var.versioning.enabled
      error_message = "Versioning must be enabled if replication_mode is set."
    }
  }
}

locals {
  replication_mode_two_way = "two-way"
  replication_mode_one_way = "one-way"
}

# Two-Way replication (A <-> B)
resource "minio_iam_policy" "replication_in_a" {
  count = var.replication.mode == local.replication_mode_two_way ? 1 : 0

  name   = "bucket-replication-${var.bucket_name}"
  policy = data.minio_iam_policy_document.replication_policy[0].json
}

resource "minio_iam_user" "replication_in_a" {
  count = var.replication.mode == local.replication_mode_two_way ? 1 : 0

  name          = var.replication.user_name == "" ? "replication-${var.bucket_name}" : var.replication.user_name
  force_destroy = true
}

resource "minio_iam_user_policy_attachment" "replication_in_a" {
  count = var.replication.mode == local.replication_mode_two_way ? 1 : 0

  user_name   = minio_iam_user.replication_in_a[0].name
  policy_name = minio_iam_policy.replication_in_a[0].id
}

resource "minio_iam_service_account" "replication_in_a" {
  count = var.replication.mode == local.replication_mode_two_way ? 1 : 0

  target_user = minio_iam_user.replication_in_a[0].name

  depends_on = [
    minio_iam_user_policy_attachment.replication_in_b
  ]
}

resource "minio_s3_bucket_replication" "replication_in_a" {
  count = var.replication.mode == local.replication_mode_two_way ? 1 : 0

  provider = minio.deployment_b
  bucket   = minio_s3_bucket.bucket_in_b[0].bucket

  rule {
    delete_marker_replication   = var.replication.delete_marker_replication
    delete_replication          = var.replication.delete_replication
    enabled                     = var.replication.enabled
    existing_object_replication = var.replication.existing_object_replication
    metadata_sync               = var.replication.metadata_sync
    prefix                      = var.replication.prefix
    priority                    = var.replication.priority
    tags                        = var.replication.tags

    target {
      bucket          = minio_s3_bucket.bucket_in_a.bucket
      secure          = startswith(var.replication.site_a_endpoint, "https://")
      host            = replace(replace(var.replication.site_a_endpoint, "https://", ""), "http://", "")
      bandwidth_limit = var.replication.bandwidth_limit
      region          = var.region
      access_key      = minio_iam_service_account.replication_in_a[0].access_key
      secret_key      = minio_iam_service_account.replication_in_a[0].secret_key
    }
  }

  depends_on = [
    minio_s3_bucket_versioning.bucket_in_a,
    minio_s3_bucket_versioning.bucket_in_b,
  ]

  lifecycle {
    precondition {
      condition     = !(var.replication.metadata_sync && var.replication.mode != local.replication_mode_two_way)
      error_message = "replication_metadata_sync must be true when two_way_replication is enabled."
    }

    precondition {
      condition     = var.replication.mode == "two-way" && var.replication.site_a_endpoint != ""
      error_message = "endpoint for site a must be set if replication_mode is set to two-way"
    }

    precondition {
      condition     = var.replication.mode != "" && var.versioning.enabled
      error_message = "Versioning must be enabled if replication_mode is set."
    }
  }
}
