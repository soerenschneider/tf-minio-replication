locals {
  directory_name = coalesce(var.directory_name, var.user_name)
}

resource "minio_iam_policy" "restic" {
  name = "restic-${var.user_name}-${local.directory_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Principal = "*"
        Resource = [
          "arn:aws:s3:::${var.bucket_name}"
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "${local.directory_name}/"
            ]
          }
        }
      },
      {
        Sid    = "WriteBucket"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
        ]
        Principal = "*"
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/${local.directory_name}",
          "arn:aws:s3:::${var.bucket_name}/${local.directory_name}/*"
        ]
      }
    ]
  })
}

resource "minio_iam_user_policy_attachment" "developer" {
  user_name   = minio_iam_user.user.id
  policy_name = minio_iam_policy.restic.id
}
