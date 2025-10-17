resource "minio_iam_user" "user" {
  name          = var.user_name
  force_destroy = var.force_destroy
}

# Create access key for user
resource "minio_iam_service_account" "user_key" {
  target_user = minio_iam_user.user.name
}

# Generate JSON IAM-style policy for MinIO
data "minio_iam_policy_document" "minio_user_policy" {
  # READ access
  dynamic "statement" {
    for_each = local.has_read_access ? [1] : []
    content {
      actions = [
        "s3:GetObject"
      ]
      resources = local.read_resources
    }
  }

  # LIST access (only if read access is configured)
  dynamic "statement" {
    for_each = local.has_read_access ? [1] : []
    content {
      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::${var.bucket_name}"]

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = local.read_prefixes
      }
    }
  }

  # WRITE access
  dynamic "statement" {
    for_each = local.has_write_access ? [1] : []
    content {
      actions = [
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      resources = local.write_resources
    }
  }
}

# MinIO policy resource
resource "minio_iam_policy" "user_policy" {
  name   = "${var.user_name}-policy"
  policy = data.minio_iam_policy_document.minio_user_policy.json
}

# Attach policy to user
resource "minio_iam_user_policy_attachment" "user_attach" {
  user_name   = minio_iam_user.user.name
  policy_name = minio_iam_policy.user_policy.name
}

