locals {
  sanitized_prefix = replace(lower(var.prefix), "_", "-")
  vm_name          = "${local.sanitized_prefix}-runner"

  common_tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.prefix
  }

  # Whether to include org name in resource name prefix
  include_org_in_prefix = false
}
