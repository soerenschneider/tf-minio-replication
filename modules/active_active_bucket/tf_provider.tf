terraform {
  required_version = ">= 1.7.0"
  required_providers {
    minio = {
      source  = "registry.terraform.io/aminueza/minio"
      version = "3.8.0"
      configuration_aliases = [
        minio.deployment_b
      ]
    }
  }
}
