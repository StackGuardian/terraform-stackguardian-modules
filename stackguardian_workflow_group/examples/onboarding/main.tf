module "stackguardian_workflow_group" {
    source = "../.."
    api_key = var.api_key
    workflow_group_name = var.workflow_group_name
    org_name = var.org_name
}