resource "stackguardian_role" "role" {

  resource_name = var.role_name
  description   = "Onboarding example of terraform-provider-stackguardian for Role Developer"
  tags = [
    "demo-org"
  ]
    allowed_permissions = local.team_onboarding_permissions

}
