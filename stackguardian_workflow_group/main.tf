resource "stackguardian_workflow_group" "Example-WorkflowGroup" {
  for_each = toset(var.workflow_groups)
  data = jsonencode({
    "ResourceName" : each.key,
    "Description" : "Example of terraform-provider-stackguardian for WorkflowGroup",
    "Tags" : ["tf-provider-example"],
    "IsActive" : 1,
  })
}
