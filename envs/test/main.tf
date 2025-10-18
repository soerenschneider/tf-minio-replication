locals {
  instance                     = basename(abspath(path.module))
  password_store_paths_default = ["env/${local.instance}/minio/hosts/%s/svcaccount/%s"]
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

  host_nice_name = each.value.host_nice_name
  create_user          = each.value.create_user
  password_store_paths = coalescelist(each.value.password_store_paths, var.password_store_paths, local.password_store_paths_default)

  force_destroy = local.instance == "dev" ? true : false
}

module "users" {
  source = "../../modules/users"
  for_each = {
    for x in var.users : x.name => x
  }

  user_name            = each.value.name
  buckets = each.value.buckets
  host_nice_name = each.value.host_nice_name
  password_store_paths = coalescelist(each.value.password_store_paths, var.password_store_paths, local.password_store_paths_default)
}

locals {
  # Flatten users - already in the right format (one access_keys object per user)
  users_for_vault = {
    for k, v in module.users : k => v
  }

  # Flatten bucket access keys - create one entry per access key in the list
  bucket_keys_for_vault = merge([
    for bucket_key, bucket_value in module.bucket : {
      for idx, access_key in bucket_value.access_keys :
      "${bucket_key}-${idx}" => merge(bucket_value, {
        access_keys = access_key # Single object, not a list
      })
    }
  ]...)
}

module "vault" {
  for_each = merge(
    local.users_for_vault,
    local.bucket_keys_for_vault
  )

  source      = "../../modules/vault"
  access_keys = nonsensitive(each.value.access_keys)
  password_store_paths = coalescelist(
    each.value.password_store_paths,
    var.password_store_paths,
    local.password_store_paths_default
  )
  metadata = {
    env = local.instance
  }
}
