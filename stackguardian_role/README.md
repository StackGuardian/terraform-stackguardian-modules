# StackGuardian Role v4

Creates a StackGuardian `rolev4` resource using workflow, connector, and template collections. Configure the StackGuardian provider in the calling root. Existing `stackguardian_role` state must be removed and imported at the v4 address; see the root README.

```hcl
module "role" {
  source          = "./stackguardian_role"
  org_name         = "example-org"
  role_name        = "developer"
  workflow_groups  = ["engineering"]
  cloud_connectors = ["aws-rbac"]
  vcs_connectors   = ["github"]
  template_list    = ["terraform-aws-vpc"]
}
```

Output: `role`.
