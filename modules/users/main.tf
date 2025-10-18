resource "minio_iam_user" "user" {
  name          = var.user_name
  force_destroy = var.force_destroy
}

# Create access key for user
resource "minio_iam_service_account" "user_key" {
  target_user = minio_iam_user.user.name
}

locals {
  # Compute resources and prefixes per bucket
  user_bucket_resources = {
    for bucket_name, bucket in var.buckets :
    bucket_name => {
      read_resources = [
        for path in bucket.read_paths :
        path == "/" ? "arn:aws:s3:::${bucket_name}/*" : "arn:aws:s3:::${bucket_name}${path}/*"
        if trimspace(path) != ""
      ]
      write_resources = [
        for path in bucket.write_paths :
        path == "/" ? "arn:aws:s3:::${bucket_name}/*" : "arn:aws:s3:::${bucket_name}${path}/*"
        if trimspace(path) != ""
      ]
      read_prefixes = [
        for path in bucket.read_paths :
        path == "/" ? "*" : "${trimprefix(path, "/")}/*"
      ]
    }
  }
}

data "minio_iam_policy_document" "minio_user_policy" {
  # READ access (GetObject)
  dynamic "statement" {
    for_each = {
      for bucket_name, bucket in local.user_bucket_resources :
      bucket_name => bucket if length(bucket.read_resources) > 0
    }
    content {
      actions   = ["s3:GetObject"]
      resources = statement.value.read_resources
    }
  }

  # LIST access (ListBucket)
  dynamic "statement" {
    for_each = {
      for bucket_name, bucket in local.user_bucket_resources :
      bucket_name => bucket if length(bucket.read_resources) > 0
    }
    content {
      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::${statement.key}"]

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = statement.value.read_prefixes
      }
    }
  }

  # WRITE access (PutObject/DeleteObject)
  dynamic "statement" {
    for_each = {
      for bucket_name, bucket in local.user_bucket_resources :
      bucket_name => bucket if length(bucket.write_resources) > 0
    }
    content {
      actions   = ["s3:PutObject", "s3:DeleteObject"]
      resources = statement.value.write_resources
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

