module "stackguardian_workflow_group" {
    source = "../.."
    api_key = var.api_key
    connector = var.connector
    org_name = var.org_name
    awsaccesskey = var.awsaccesskey
    awssecretaccesskey = var.awssecretaccesskey
    region = var.region
}