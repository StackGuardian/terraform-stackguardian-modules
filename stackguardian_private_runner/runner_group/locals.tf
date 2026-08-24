locals {
  # Storage backend discriminator
  is_aws   = var.storage_backend.type == "aws_s3"
  is_azure = var.storage_backend.type == "azure_blob_storage"

  aws_backend   = var.storage_backend.aws
  azure_backend = var.storage_backend.azure

  # Default tags (not editable by user)
  default_tags = [
    "StackGuardian Private Runner",
    var.runner_group_name,
    var.sg_org_name
  ]
}
