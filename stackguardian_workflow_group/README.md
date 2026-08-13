# StackGuardian Workflow Group

Creates one StackGuardian workflow group. Configure the StackGuardian provider in the calling root.

```hcl
module "workflow_group" {
  source              = "./stackguardian_workflow_group"
  workflow_group_name = "engineering"
}
```

Output: `workflow_groups`.
