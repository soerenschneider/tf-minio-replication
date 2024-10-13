locals {
  instance                     = basename(abspath(path.module))
  password_store_paths_default = ["env/${local.instance}/minio-replication/serviceaccount/%s"]
}

module "bucket" {
  providers = {
    minio.target = minio.target
  }
  source = "../../modules/replicated_bucket"

  bucket_name   = var.bucket_name
  target_host   = var.minio_target_host
  force_destroy = local.instance == "dev" ? true : false
}

module "users" {
  source = "../../modules/users"
  for_each = {
    for x in var.users : x.name => x
  }
  bucket_name          = var.bucket_name
  user_name            = each.value.name
  password_store_paths = coalescelist(each.value.password_store_paths, var.password_store_paths, local.password_store_paths_default)
}

module "vault" {
  for_each             = { for sa in module.users : sa.access_keys.name => sa }
  source               = "../../modules/vault"
  access_keys          = nonsensitive(each.value.access_keys)
  password_store_paths = coalescelist(each.value.password_store_paths, var.password_store_paths, local.password_store_paths_default)
  metadata             = {}
}
