locals {
  # Azure resource names are lowercase-and-hyphens; matches how the modules
  # derive their own names from override_names.global_prefix.
  sanitized_prefix = replace(lower(var.override_names.global_prefix), "_", "-")

  common_tags = {
    purpose = "stackguardian-private-runner"
    prefix  = var.override_names.global_prefix
  }
}
