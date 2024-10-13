#!/usr/bin/env bash

set -eu

ENV="${1:-prod}"

echo "Running tofu apply for env ${ENV}"

MINIO_SOURCE_SECRET_PATH="infra/selfhosted/minio/minio-${ENV}"
MINIO_DEST_SECRET_PATH="infra/selfhosted/minio/minio-rs"
TF_SECRET_PATH="infra/selfhosted/terraform-state/tf-minio-${ENV}"

echo "Reading minio credentials for source..."
OUTPUT=$(pass "${MINIO_SOURCE_SECRET_PATH}")
TF_VAR_minio_source_user=$(echo "${OUTPUT}" | grep ^MINIO_USERNAME= | cut -d'=' -f2)
export TF_VAR_minio_source_user

TF_VAR_minio_source_password=$(echo "${OUTPUT}" | grep ^MINIO_PASSWORD= | cut -d'=' -f2)
export TF_VAR_minio_source_password

###################

echo "Reading minio credentials for target..."
OUTPUT=$(pass "${MINIO_DEST_SECRET_PATH}")
TF_VAR_minio_target_user=$(echo "${OUTPUT}" | grep ^MINIO_USERNAME= | cut -d'=' -f2)
export TF_VAR_minio_target_user

TF_VAR_minio_target_password=$(echo "${OUTPUT}" | grep ^MINIO_PASSWORD= | cut -d'=' -f2)
export TF_VAR_minio_target_password

###################

echo "Reading opentofu state encryption key..."
OUTPUT=$(pass "${TF_SECRET_PATH}")
_TF_KEY=$(echo "${OUTPUT}" | head -n1)
export _TF_KEY

TF_ENCRYPTION=$(cat <<EOF
key_provider "pbkdf2" "mykey" {
  passphrase = "${_TF_KEY}"
}
EOF
)
export TF_ENCRYPTION

terragrunt --terragrunt-working-dir="envs/${ENV}" apply
