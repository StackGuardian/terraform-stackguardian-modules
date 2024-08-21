resource "stackguardian_role" "role" {
  data = jsonencode({
    "ResourceName" : var.role_name,
    "Description" : "Role in Stackguardian",
    "Tags" : ["tf-provider-example", "onboarding"],
    "Actions" : [
      var.org_name,
    ],
    "AllowedPermissions" : var.allowed_permissions
  })
}

