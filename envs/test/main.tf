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

  bucket_name           = each.value.name

  versioning = each.value.versioning

  lifecycle_rules       = each.value.lifecycle_rules
  site_a_endpoint       = "https://nas.dd.soeren.cloud:443"
  site_b_endpoint       = "https://nas.ez.soeren.cloud:443"
  region_site_a         = "dd"
  region_site_b         = "ez"
  replication_user_name = "replication"
  replication_mode      = "two-way"

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

# ----

resource "minio_iam_user" "prometheus" {
  name = "prometheus"
}

resource "minio_iam_policy" "prometheus_metrics" {
  name = "prometheus-metrics-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["admin:Prometheus"],
      Resource = ["arn:aws:s3:::*"]
    }]
  })
}

resource "minio_iam_user_policy_attachment" "prometheus_attach" {
  user_name   = minio_iam_user.prometheus.name
  policy_name = minio_iam_policy.prometheus_metrics.name
}

output "prometheus_access_key" {
  value     = minio_iam_user.prometheus.id
  sensitive = true
}

output "prometheus_secret_key" {
  value     = minio_iam_user.prometheus.secret
  sensitive = true
}

