module "stackguardian_connector_cloud" {
    source = "../.."
    api_key = var.api_key
    connector = var.connector
    org_name = var.org_name
    awsaccesskey = var.awsaccesskey
    awssecretaccesskey = var.awssecretaccesskey
    region = var.region
}
