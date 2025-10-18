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

  create_user          = each.value.create_user
  password_store_paths = each.value.password_store_paths

  force_destroy = local.instance == "dev" ? true : false
}

module "users" {
  source = "../../modules/users"
  for_each = {
    for x in var.users : x.name => x
  }

  users = {
    user_name = "test"
    buckets = {
      "replicationtest" = {
        read_paths  = ["/"]
        write_paths = ["/uploads"]
      }
    }
  }
  bucket_name          = "replicationtest"
  user_name            = each.value.name
  password_store_paths = coalescelist(each.value.password_store_paths, var.password_store_paths, local.password_store_paths_default)
}


module "vault" {
  # merge non-empty implicit users and explicit users
  for_each = {
    for k, v in merge([
      for m in [module.users, module.bucket] : m
      if length(m) > 0
    ]...) : k => v
  }

  source               = "../../modules/vault"
  access_keys          = nonsensitive(each.value.access_keys)
  password_store_paths = coalescelist(each.value.password_store_paths, var.password_store_paths, local.password_store_paths_default)
  metadata             = {}
}
