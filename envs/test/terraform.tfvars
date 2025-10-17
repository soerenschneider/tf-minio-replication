minio_source_password = "minioadmin"
minio_source_user     = "minioadmin"

minio_target_password = "minioadmin"
minio_target_user     = "minioadmin"
minio_target_host     = "http://minio2:9002"

bucket_name = "replicated-2"
users = [
  {
    name = "test"
  }
]

lifecycle_rules = [
  {
    id      = "test"
    enabled = true
    noncurrent_expirations = [{
      days = 1
      newer_versions = 3
    }]
  }
]
