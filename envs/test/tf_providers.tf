terraform {
  required_version = ">= 1.7.0"
  required_providers {
    minio = {
      source  = "registry.terraform.io/aminueza/minio"
      version = "3.8.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "4.4.0"
    }
  }
}

provider "minio" {
  minio_server   = "nas.dd.soeren.cloud:443"
  minio_user     = "soeren"
  minio_password = "IeGh6ieph6aiw2ea3foomienihahbaeDughaizi9du4paelah?t"
  minio_ssl      = true
}

provider "minio" {
  alias          = "site_b"
  minio_server   = "nas.ez.soeren.cloud:443"
  minio_user     = "soeren"
  minio_password = "IeGh6ieph6aiw2ea3foomienihahbaeDughaizi9du4paelah?t"
  minio_ssl      = true
}
