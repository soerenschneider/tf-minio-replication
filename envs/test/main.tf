locals {
  instance                     = basename(abspath(path.module))
  password_store_paths_default = ["env/${local.instance}/minio-replication/serviceaccount/%s"]
}

module "bucket" {
  providers = {
    minio.deployment_b = minio.site_b
  }
  source = "../../modules/active_active_bucket"

  for_each = {
    for x in var.buckets : x.name => x
  }

  bucket_name     = each.value.name
  region          = each.value.region
  versioning      = each.value.versioning
  lifecycle_rules = each.value.lifecycle_rules
  replication     = each.value.replication

  force_destroy = local.instance == "dev" ? true : false
}

module "users" {
  source = "../../modules/users"
  for_each = {
    for x in var.users : x.name => x
  }
  bucket_name          = "replicationtest"
  user_name            = each.value.name
  password_store_paths = coalescelist(each.value.password_store_paths, var.password_store_paths, local.password_store_paths_default)
}
