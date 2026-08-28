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
  # Use nonsensitive() for non-secret fields to prevent sensitivity propagation
  sg_org_name = (
    nonsensitive(var.stackguardian.org_name) != ""
    ? nonsensitive(var.stackguardian.org_name)
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = nonsensitive(var.stackguardian.api_uri)

  # Web console URL per platform region. Kept as an explicit map because the
  # console host is not derivable from the API host in every region.
  sg_app_uris = {
    "https://api.app.stackguardian.io"    = "https://app.stackguardian.io"
    "https://api.us.stackguardian.io"     = "https://us.stackguardian.io"
    "https://testapi.qa.stackguardian.io" = "https://dash.qa.stackguardian.io"
  }
  sg_app_uri = local.sg_app_uris[local.sg_api_uri]

  # Platform naming: {prefix}-{name}, or just {name} when no prefix is set.
  # The name half is yours to pick; left empty it is a random suffix, which is
  # all the uniqueness a runner group needs. The account ID used to sit here -
  # it is a tag now.
  runner_group_base = (
    var.override_names.runner_group_name != ""
    ? var.override_names.runner_group_name
    : random_string.name_suffix.result
  )

  runner_group_name = (
    var.override_names.global_prefix != ""
    ? "${var.override_names.global_prefix}-${local.runner_group_base}"
    : local.runner_group_base
  )

  # The connector is created 1:1 with the runner group and shares its name -
  # they live in separate API namespaces (/integrations/ vs runnergroups/).
  connector_base = (
    var.override_names.connector_name != ""
    ? var.override_names.connector_name
    : local.runner_group_base
  )

  connector_name = (
    var.override_names.global_prefix != ""
    ? "${var.override_names.global_prefix}-${local.connector_base}"
    : local.connector_base
  )

  # Bare values - the platform's tags are a flat list of strings with no keys.
  platform_tags = compact([
    data.aws_caller_identity.current.account_id,
    var.override_names.global_prefix,
    var.aws_region,
  ])

  # S3 bucket name / ARN
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

  connector_external_id = "${local.sg_org_name}:${random_string.connector_external_id.result}"
}
