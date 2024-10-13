resource "minio_s3_bucket" "dest" {
  provider      = minio.target
  force_destroy = var.force_destroy
  bucket        = var.bucket_name
}

resource "minio_s3_bucket_versioning" "dest" {
  provider = minio.target
  bucket   = minio_s3_bucket.dest.bucket

  versioning_configuration {
    status = "Enabled"
  }
}
