terraform {
  required_version = ">= 1.7.0"
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "2.5.0"
    }
  }
}
