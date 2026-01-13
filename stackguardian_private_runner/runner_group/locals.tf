data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\"}'"
  ]
}

data "aws_caller_identity" "current" {}

locals {
  # StackGuardian configuration
  sg_org_name = (
    var.stackguardian.org_name != ""
    ? var.stackguardian.org_name
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = var.stackguardian.api_uri

  # Computed prefix with optional org name
  effective_prefix = (
    var.override_names.include_org_in_prefix
    ? "${var.override_names.global_prefix}_${local.sg_org_name}"
    : var.override_names.global_prefix
  )

  # Resource naming
  runner_group_name = (
    var.override_names.runner_group_name != ""
    ? var.override_names.runner_group_name
    : "${local.effective_prefix}-runner-group-${data.aws_caller_identity.current.account_id}"
  )

  connector_name = (
    var.override_names.connector_name != ""
    ? var.override_names.connector_name
    : "${local.effective_prefix}-private-runner-backend-${data.aws_caller_identity.current.account_id}"
  )

  # Default tags (not editable by user)
  default_tags = [
    "StackGuardian Private Runner",
    local.runner_group_name,
    local.sg_org_name
  ]

  # S3 bucket name (created or existing)
  s3_bucket_name = (
    var.create_storage_backend
    ? aws_s3_bucket.this[0].bucket
    : var.existing_s3_bucket_name
  )

  s3_bucket_arn = (
    var.create_storage_backend
    ? aws_s3_bucket.this[0].arn
    : "arn:aws:s3:::${local.s3_bucket_name}"
  )

  # Runner group outputs
  final_runner_group_name = stackguardian_runner_group.this.resource_name
  final_connector_name    = stackguardian_connector.this.resource_name
}
