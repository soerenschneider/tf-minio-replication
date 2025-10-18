resource "minio_iam_user" "user" {
  count = var.create_user ? 1 : 0

  name          = var.bucket_name
  force_destroy = true
}

# Create access key for user
resource "minio_iam_service_account" "user_key" {
  count       = var.create_user ? 1 : 0
  target_user = minio_iam_user.user[0].name
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
resource "minio_iam_policy" "user_policy" {
  count = var.create_user ? 1 : 0

  name   = "implicit-user-${var.bucket_name}"
  policy = data.minio_iam_policy_document.implicit.json
}

# Attach policy to user
resource "minio_iam_user_policy_attachment" "user_attach" {
  count = var.create_user ? 1 : 0

  user_name   = minio_iam_user.user[0].name
  policy_name = minio_iam_policy.user_policy[0].name
}

