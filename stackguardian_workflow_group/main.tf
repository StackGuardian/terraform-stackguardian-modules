resource "stackguardian_workflow_group" "workflow-group" {
  resource_name = var.workflow_group_name
  description   = "Terraform-managed StackGuardian workflow group."
  tags          = ["terraform", "workflow-group"]
}
