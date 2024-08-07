resource "stackguardian_workflow_group" "Example-WorkflowGroup" {
  data = jsonencode({
    "ResourceName" : var.ResourceName,
    "Description" : "Example of terraform-provider-stackguardian for WorkflowGroup",
    "Tags" : ["tf-provider-example"],
    "IsActive" : 1,
  })
}
