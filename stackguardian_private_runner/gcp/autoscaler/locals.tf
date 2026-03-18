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

  # GCP resources need lowercase names with hyphens
  effective_prefix_lower = lower(replace(local.effective_prefix, "_", "-"))

  # Cloud Function build directory and zip path
  function_build_dir = "${path.module}/.function_build"
  function_zip_path  = "${local.function_build_dir}/function.zip"

  # Cloud Function name
  cloud_function_name = "${local.effective_prefix_lower}-autoscale-private-runner"
}
