module "stackguardian_workflow_group" {
    for_each = toset(var.workflow_groups)
    source = "../.."
    workflow_group_name = each.key
}
