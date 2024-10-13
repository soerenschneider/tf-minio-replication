terraform {
  required_version = ">= 1.7.0"
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "2.5.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "4.4.0"
    }
  }
}

provider "minio" {
  minio_server   = "127.0.0.1:9000"
  minio_user     = var.minio_source_user
  minio_password = var.minio_source_password
  minio_ssl      = false
}

provider "minio" {
  alias          = "target"
  minio_server   = "127.0.0.1:9002"
  minio_user     = var.minio_target_user
  minio_password = var.minio_target_password
  minio_ssl      = false
}

provider "vault" {
  address = "http://localhost:8200"
  token   = "test"
}
