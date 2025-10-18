resource "minio_iam_user" "implicit_user_in_a" {
  count = var.create_user ? 1 : 0

  name          = var.bucket_name
  force_destroy = true
}

resource "minio_iam_user" "implicit_user_in_b" {
  count    = var.create_user && var.replication.mode != "" ? 1 : 0
  provider = minio.deployment_b

  name          = var.bucket_name
  force_destroy = true
}

resource "minio_iam_service_account" "implicit_user_key_in_a" {
  count       = var.create_user ? 1 : 0
  target_user = minio_iam_user.implicit_user_in_a[0].name
}

resource "minio_iam_service_account" "implicit_user_key_in_b" {
  count    = var.create_user && var.replication.mode != "" ? 1 : 0
  provider = minio.deployment_b

  target_user = minio_iam_user.implicit_user_in_a[0].name
}

# MinIO IAM policy document
data "minio_iam_policy_document" "implicit" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }

  statement {
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.bucket_name}"
    ]
  }
}

# MinIO policy resource
resource "minio_iam_policy" "implicit_user_policy_in_a" {
  count = var.create_user ? 1 : 0

  name   = "implicit-user-${var.bucket_name}"
  policy = data.minio_iam_policy_document.implicit.json
}

resource "minio_iam_policy" "implicit_user_policy_in_b" {
  count    = var.create_user && var.replication.mode != "" ? 1 : 0
  provider = minio.deployment_b

  name   = "implicit-user-${var.bucket_name}"
  policy = data.minio_iam_policy_document.implicit.json
}

# Attach policy to user
resource "minio_iam_user_policy_attachment" "implicit_user_attachment_in_a" {
  count = var.create_user ? 1 : 0

  user_name   = minio_iam_user.implicit_user_in_a[0].name
  policy_name = minio_iam_policy.implicit_user_policy_in_a[0].name
}

resource "minio_iam_user_policy_attachment" "implicit_user_attachment_in_b" {
  count    = var.create_user && var.replication.mode != "" ? 1 : 0
  provider = minio.deployment_b

  user_name   = minio_iam_user.implicit_user_in_b[0].name
  policy_name = minio_iam_policy.implicit_user_policy_in_b[0].name
}

