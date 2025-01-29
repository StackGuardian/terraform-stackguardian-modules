resource "stackguardian_workflow_group" "workflow-group" {
  resource_name = var.workflow_group_name
  description   = "Onboarding example  of terraform-provider-stackguardian for WorkflowGroup"
  tags          = ["tf-provider-example", "onboarding"]
}
