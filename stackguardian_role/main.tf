resource "stackguardian_rolev4" "role" {
  resource_name       = var.role_name
  description         = "Scoped workflow, connector, and template access for ${var.role_name}."
  tags                = ["terraform", "scoped-access"]
  allowed_permissions = local.team_onboarding_permissions

}
