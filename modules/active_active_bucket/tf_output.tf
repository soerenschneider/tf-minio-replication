output "access_keys" {
  value = var.create_user ? {
    name       = minio_iam_user.user[0].name
    access_key = minio_iam_service_account.user_key[0].access_key
    secret_key = minio_iam_service_account.user_key[0].secret_key
  } : {}
}
