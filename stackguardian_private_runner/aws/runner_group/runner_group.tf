# StackGuardian Runner Group + connector.
#
# The platform resources live in the shared, cloud-agnostic module so that this
# template only ever requires the AWS provider — an AWS deployment never pulls in
# azurerm/azuread.

# Random half of the runner group name, used when no name is supplied. Held in
# state, so it is stable across applies and only changes if this is replaced.
resource "random_string" "name_suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

module "runner_group" {
  source = "../../runner_group"

  sg_org_name = local.sg_org_name
  sg_app_uri  = local.sg_app_uri

  runner_group_name = local.runner_group_name
  connector_name    = local.connector_name
  max_runners       = var.max_runners

  tags = local.platform_tags

  storage_backend = {
    type = "aws_s3"
    aws = {
      region      = var.aws_region
      bucket_name = local.s3_bucket_name
      role_arn    = aws_iam_role.storage_backend.arn
      external_id = local.connector_external_id
    }
  }
}
