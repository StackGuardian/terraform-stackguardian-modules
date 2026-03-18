# Extract SG org name from environment if not provided
data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\"}'"
  ]
}

locals {
  # StackGuardian configuration - use provided values or extract from environment
  # Use nonsensitive() for non-secret fields to prevent sensitivity propagation
  sg_org_name = (
    nonsensitive(var.stackguardian.org_name) != ""
    ? nonsensitive(var.stackguardian.org_name)
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = nonsensitive(var.stackguardian.api_uri)

  # Effective prefix for resource naming (optionally includes org name)
  effective_prefix = (
    var.override_names.include_org_in_prefix && local.sg_org_name != ""
    ? "${var.override_names.global_prefix}_${local.sg_org_name}"
    : var.override_names.global_prefix
  )

  # GCP-safe prefix (lowercase, hyphens only - GCP resource names don't allow underscores)
  effective_prefix_lower = lower(replace(local.effective_prefix, "_", "-"))

  # Whether to create Cloud NAT infrastructure
  create_cloud_nat = var.network.create_cloud_nat

  # MIG name
  mig_name = "${local.effective_prefix_lower}-private-runner-mig"

  # S3 bucket ARN for IAM policy
  s3_bucket_arn = "arn:aws:s3:::${var.s3_bucket_name}"
}
