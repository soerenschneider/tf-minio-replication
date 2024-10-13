resource "minio_iam_user" "replication" {
  provider = minio.target
  name     = "replication-${var.bucket_name}"
  #force_destroy = true
}

resource "minio_iam_user_policy_attachment" "replication" {
  provider    = minio.target
  user_name   = minio_iam_user.replication.name
  policy_name = minio_iam_policy.replication.id
}

resource "minio_iam_service_account" "replication" {
  provider    = minio.target
  target_user = minio_iam_user.replication.name

  depends_on = [
    minio_iam_user_policy_attachment.replication
  ]
}
