resource "stackguardian_workflow_group" "Example-WorkflowGroup" {
  data = jsonencode({
    "ResourceName" : var.workflow_group_name,
    "Description" : "Example of terraform-provider-stackguardian for WorkflowGroup",
    "Tags" : ["tf-provider-example"],
    "IsActive" : 1,
  })
}
