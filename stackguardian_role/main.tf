resource "stackguardian_rolev4" "role" {
  resource_name = var.role_name
  description   = "Onboarding example of terraform-provider-stackguardian for Role Developer"
  tags = [
    var.org_name
  ]
  allowed_permissions = local.team_onboarding_permissions

}
