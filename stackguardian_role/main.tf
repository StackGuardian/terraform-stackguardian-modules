resource "stackguardian_role" "role" {

  data = jsonencode({
    "ResourceName" : var.role_name,
    "Description" : "Role in Stackguardian",
    "Tags" : ["tf-role", "onboarding"],
    "Actions" : [
      var.org_name,
    ],
    "AllowedPermissions" : local.team_onboarding_permissions
  })
}

