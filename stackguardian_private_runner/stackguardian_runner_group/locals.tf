data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\", \"sg_api_uri\": \"'$${SG_API_URI:-https://api.app.stackguardian.io}'\"}'"
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
  sg_api_uri = data.external.env.result.sg_api_uri

  # Resource naming
  runner_group_name = (
    var.override_names.runner_group_name != ""
    ? var.override_names.runner_group_name
    : "${var.override_names.global_prefix}-runner-group-${data.aws_caller_identity.current.account_id}"
  )

  connector_name = (
    var.override_names.connector_name != ""
    ? var.override_names.connector_name
    : "${var.override_names.global_prefix}-private-runner-backend-${data.aws_caller_identity.current.account_id}"
  )

  # Determine which resources to use (created vs existing)
  use_existing = var.mode == "existing"

  # S3 bucket name (created or existing)
  s3_bucket_name = (
    var.create_storage_backend
    ? (var.mode == "create" ? aws_s3_bucket.this[0].bucket : data.stackguardian_runner_group.existing[0].storage_backend_config.s3_bucket_name)
    : var.existing_s3_bucket_name
  )

  s3_bucket_arn = (
    var.create_storage_backend && var.mode == "create"
    ? aws_s3_bucket.this[0].arn
    : "arn:aws:s3:::${local.s3_bucket_name}"
  )

  # Runner group outputs (from created or existing)
  final_runner_group_name = (
    var.mode == "create"
    ? stackguardian_runner_group.this[0].resource_name
    : data.stackguardian_runner_group.existing[0].resource_name
  )

  final_connector_name = (
    var.mode == "create"
    ? stackguardian_connector.this[0].resource_name
    : ""  # Existing mode doesn't create connector, use existing from runner group
  )
}
