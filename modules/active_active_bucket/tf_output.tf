output "access_keys" {
  value = var.create_user ? concat(
    [
      {
        name           = minio_iam_user.implicit_user_in_a[0].name
        bucket_name    = var.bucket_name
        host_nice_name = var.host_nice_name
        access_key     = minio_iam_service_account.implicit_user_key_in_a[0].access_key
        secret_key     = minio_iam_service_account.implicit_user_key_in_a[0].secret_key
      }
    ],
    var.replication.mode != "" ? [
      {
        name           = minio_iam_user.implicit_user_in_b[0].name
        bucket_name    = var.bucket_name
        host_nice_name = var.replication.site_b_nice_name
        access_key     = minio_iam_service_account.implicit_user_key_in_b[0].access_key
        secret_key     = minio_iam_service_account.implicit_user_key_in_b[0].secret_key
      }
    ] : []
  ) : []
}

output "password_store_paths" {
  value = var.password_store_paths
}
