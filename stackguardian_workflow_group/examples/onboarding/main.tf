module "stackguardian_workflow_group" {
    for_each = toset(var.workflow_groups)
    source = "../.."
    api_key = var.api_key
    workflow_group_name = each.key
    org_name = var.org_name
}