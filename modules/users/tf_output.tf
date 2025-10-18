output "access_keys" {
  value = {
    name        = minio_iam_user.user.name
    host_nice_name = var.host_nice_name

    access_key = minio_iam_service_account.user_key.access_key
    secret_key = minio_iam_service_account.user_key.secret_key
  }
}

output "password_store_paths" {
  value = var.password_store_paths
}

output "policy_name" {
  description = "Name of the created policy"
  value       = minio_iam_policy.user_policy.name
}

