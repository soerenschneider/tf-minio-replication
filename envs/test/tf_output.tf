output "minio_local_credentials" {
  value = {
    for k, v in module.users : k => v.access_keys
  }
  sensitive = true
}

# output "minio_local_bucket_url" {
#   value = module.bucket.minio_local_bucket_url
# }
