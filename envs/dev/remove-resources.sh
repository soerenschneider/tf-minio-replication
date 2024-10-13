#!/bin/bash

# Check if tofu command is available
if ! command -v tofu &> /dev/null; then
    echo "OpenTofu command not found. Please install OpenTofu first."
    exit 1
fi

tofu destroy --target module.bucket.minio_s3_bucket_replication.repl

# List of resources to remove from state
resources=(
    "module.bucket.minio_s3_bucket.dest"
    "module.bucket.minio_s3_bucket_versioning.dest"
    "module.bucket.minio_iam_policy.mirror"
    "module.bucket.minio_iam_user.mirror"
    "module.bucket.minio_iam_user_policy_attachment.mirror"
    "module.bucket.minio_iam_service_account.mirror"
    "module.bucket.minio_iam_service_account.replication"
    "module.bucket.minio_iam_user_policy_attachment.replication"
)

# Loop through each resource and remove it from state
for resource in "${resources[@]}"; do
    echo "Removing resource: $resource"
    tofu state rm "$resource"
done

echo "Resources removed from state successfully."
