resource "stackguardian_workflow_group" "Example-WorkflowGroup" {
  for_each = toset(var.workflow_groups)
  data = jsonencode({
    "ResourceName" : each.key,
    "Description" : "WorkflowGroup for Environment X",
    "Tags" : ["tf-provider-example"],
    "IsActive" : 1,
  })
}
