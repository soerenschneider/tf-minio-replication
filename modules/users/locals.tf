locals {
  # Normalize paths: "/" becomes "*", others become "path/*"
  read_resources = [
    for path in var.read_paths :
    path == "/" ? "arn:aws:s3:::${var.bucket_name}/*" : "arn:aws:s3:::${var.bucket_name}${path}/*"
  ]

  write_resources = [
    for path in var.write_paths :
    path == "/" ? "arn:aws:s3:::${var.bucket_name}/*" : "arn:aws:s3:::${var.bucket_name}${path}/*"
  ]

  # For ListBucket prefix conditions
  read_prefixes = [
    for path in var.read_paths :
    path == "/" ? "*" : "${trimprefix(path, "/")}/*"
  ]

  has_read_access  = length(var.read_paths) > 0
  has_write_access = length(var.write_paths) > 0
  has_full_read    = contains(var.read_paths, "/")
}
