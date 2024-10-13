output "minio_local_bucket_url" {
  value = minio_s3_bucket.source.bucket_domain_name
}
