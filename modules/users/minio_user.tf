resource "minio_iam_user" "user" {
  name          = var.user_name
  force_destroy = true
}

resource "minio_iam_service_account" "user" {
  target_user = minio_iam_user.user.name

  lifecycle {
    ignore_changes = [
      target_user # FIXME Workaround till https://github.com/aminueza/terraform-provider-minio/pull/547 gets merged
    ]
  }
}
