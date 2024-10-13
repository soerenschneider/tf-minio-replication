resource "minio_s3_bucket" "source" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
}

resource "minio_s3_bucket_versioning" "source" {
  bucket = minio_s3_bucket.source.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "minio_s3_bucket_replication" "repl" {
  bucket = minio_s3_bucket.source.bucket

  rule {
    delete_marker_replication   = var.replication_delete_marker_replication
    delete_replication          = var.replication_delete_replication
    enabled                     = var.replication_enabled
    existing_object_replication = var.replication_existing_object_replication
    metadata_sync               = var.replication_metadata_sync
    prefix                      = var.replication_prefix
    priority                    = var.replication_priority
    tags                        = var.replication_tags

    target {
      bucket         = minio_s3_bucket.dest.bucket
      secure         = startswith(minio_s3_bucket.dest.bucket, "https://")
      host           = replace(replace(var.target_host, "https://", ""), "http://", "")
      bandwidth_limt = var.bandwidth_limit
      region         = var.region
      access_key     = minio_iam_service_account.replication.access_key
      secret_key     = minio_iam_service_account.replication.secret_key
    }
  }

  depends_on = [
    minio_s3_bucket_versioning.source,
    minio_s3_bucket_versioning.dest
  ]
}
