resource "stackguardian_rolev4" "role" {
  resource_name       = var.role_name
  description         = "Scoped workflow, connector, and template access for ${var.role_name}."
  tags                = ["terraform", "scoped-access"]
  allowed_permissions = local.team_onboarding_permissions

  lifecycle {
    precondition {
      condition     = length(concat(var.workflow_groups, var.cloud_connectors, var.vcs_connectors, var.template_list)) > 0
      error_message = "A role must grant at least one workflow group, connector, or template."
    }
  }
}
