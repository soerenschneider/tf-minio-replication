output "access_keys" {
  value = {
    name       = minio_iam_user.user.name
    access_key = minio_iam_service_account.user.access_key
    secret_key = minio_iam_service_account.user.secret_key
  }
}

output "password_store_paths" {
  value = var.password_store_paths
}
