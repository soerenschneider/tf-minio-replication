output "minio_local_credentials" {
  value = {
    for k, v in merge([
      for m in [module.users, module.bucket] : m
      if length(m) > 0
    ]...) : k => v.access_keys
  }
  sensitive = true
}

# output "minio_local_bucket_url" {
#   value = module.bucket.minio_local_bucket_url
# }
