module "stackguardian_workflow_group" {
    source = "../.."
    api_key = var.api_key
    vcs_connector = var.vcs_connector
    org_name = var.org_name
    gitcreds = var.gitcreds
}