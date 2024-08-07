resource "stackguardian_role" "example-role" {
  data = jsonencode({
    "ResourceName" : var.roleName,
    "Description" : "Example of terraform-provider-stackguardian for Role",
    "Tags" : ["tf-provider-example", "onboarding"],
    "Actions" : [
      "wicked-hop",
    ],
    "AllowedPermissions" : {
      "Permission-key-1" : "Permission-val-1",
      "Permission-key-2" : "Permission-val-2"
    }
  })
}