resource "vault_kv_secret_v2" "tokens" {
  for_each            = { for path in var.password_store_paths : path => path }
  mount               = var.vault_kv2_mount
  name                = format(each.value, var.access_keys.name)
  delete_all_versions = true
  data_json = jsonencode(
    {
      AWS_ACCESS_KEY_ID     = var.access_keys.access_key
      AWS_SECRET_ACCESS_KEY = var.access_keys.secret_key
    }
  )
  custom_metadata {
    max_versions = 1
    data         = var.metadata
  }
}
