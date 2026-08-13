module "stackguardian_workflow_group" {
  for_each            = toset(var.workflow_groups)
  source              = "./stackguardian_workflow_group"
  workflow_group_name = each.value
}

module "stackguardian_connector_cloud" {
  for_each = {
    for connector in var.cloud_connectors : nonsensitive(connector.name) => connector
  }
  source                   = "./stackguardian_connector_cloud"
  connector_name           = each.value.name
  connector_kind           = each.value.kind
  allow_static_credentials = try(each.value.allow_static_credentials, false)
  aws_access_key_id        = try(each.value.aws_access_key_id, null)
  aws_secret_access_key    = try(each.value.aws_secret_access_key, null)
  aws_region               = try(each.value.aws_region, null)
  azure_tenant_id          = try(each.value.azure_tenant_id, null)
  azure_subscription_id    = try(each.value.azure_subscription_id, null)
  azure_client_id          = try(each.value.azure_client_id, null)
  azure_client_secret      = try(each.value.azure_client_secret, null)
  aws_role_arn             = try(each.value.aws_role_arn, null)
  aws_external_id          = try(each.value.aws_external_id, null)
  gcp_config_file_content  = try(each.value.gcp_config_file_content, null)
}

module "stackguardian_connector_vcs" {
  source         = "./stackguardian_connector_vcs"
  vcs_connectors = var.vcs_connectors
}

module "stackguardian_role" {
  source           = "./stackguardian_role"
  org_name         = var.stackguardian_org_name
  role_name        = var.role_name
  cloud_connectors = [for connector in var.cloud_connectors : connector.name]
  vcs_connectors   = [for connector in values(var.vcs_connectors) : connector.name]
  workflow_groups  = var.workflow_groups
  template_list    = var.template_list
}

module "stackguardian_role_assignment" {
  source      = "./stackguardian_role_assignment"
  role_name   = var.role_name
  subject     = var.subject
  entity_type = var.entity_type
  depends_on  = [module.stackguardian_role]
}
