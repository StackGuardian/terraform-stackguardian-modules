module "stackguardian_workflow_group" {
  for_each            = toset(var.workflow_groups)
  source              = "./stackguardian_workflow_group"
  workflow_group_name = each.value
}

locals {
  cloud_connectors = {
    for connector in var.cloud_connectors : connector.name => connector
  }
}

module "aws_rbac" {
  for_each = {
    for name, connector in local.cloud_connectors : name => connector if connector.kind == "AWS_RBAC"
  }

  source = "./aws_rbac"

  iam_role_name       = each.value.iam_role_name
  role_external_id    = each.value.aws_external_id
  policy_arn          = each.value.policy_arn
  trusted_account_ids = coalesce(try(each.value.trusted_account_ids, null), ["476299211833", "163602625436"])
}

module "aws_static" {
  for_each = {
    for name, connector in local.cloud_connectors : name => connector if connector.kind == "AWS_STATIC"
  }

  source = "./aws_static"

  aws_region               = var.aws_region
  iam_user                 = coalesce(try(each.value.iam_user_name, null), each.value.name)
  allow_static_credentials = each.value.allow_static_credentials
}

module "aws_oidc" {
  for_each = {
    for name, connector in local.cloud_connectors : name => connector if connector.kind == "AWS_OIDC"
  }

  source = "./aws_oidc"

  aws_region             = var.aws_region
  iam_role_name          = each.value.iam_role_name
  stackguardian_org_name = var.stackguardian_org_name
  policy_arn             = each.value.policy_arn
}

module "azure_oidc" {
  for_each = {
    for name, connector in local.cloud_connectors : name => connector if connector.kind == "AZURE_OIDC"
  }

  source = "./azure_oidc"

  subscription_id          = var.azure_subscription_id
  tenant_id                = var.azure_tenant_id
  application_display_name = coalesce(try(each.value.application_display_name, null), each.value.name)
  stackguardian_org_name   = var.stackguardian_org_name
  role_definition_name     = each.value.role_definition_name
}

module "azure_static" {
  for_each = {
    for name, connector in local.cloud_connectors : name => connector if connector.kind == "AZURE_STATIC"
  }

  source = "./azure_static"

  subscription_id          = var.azure_subscription_id
  tenant_id                = var.azure_tenant_id
  application_display_name = coalesce(try(each.value.application_display_name, null), each.value.name)
  role_definition_name     = each.value.role_definition_name
  allow_static_credentials = each.value.allow_static_credentials
}

module "gcp_oidc" {
  for_each = {
    for name, connector in local.cloud_connectors : name => connector if connector.kind == "GCP_OIDC"
  }

  source = "./gcp_oidc"

  providers = {
    google = google.gcp
  }

  project_id                          = var.gcp_project_id
  region                              = var.gcp_region
  stackguardian_org_id                = coalesce(var.stackguardian_org_id, var.stackguardian_org_name)
  service_account_id                  = each.value.gcp_service_account_id
  workload_identity_pool_id           = each.value.gcp_workload_pool_id
  workload_identity_pool_provider_id  = each.value.gcp_provider_id
  workload_identity_pool_display_name = each.value.name
  project_role                        = each.value.gcp_project_role
}

module "stackguardian_connector_cloud" {
  for_each = local.cloud_connectors

  source                   = "./stackguardian_connector_cloud"
  connector_name           = each.value.name
  connector_kind           = each.value.kind
  allow_static_credentials = try(each.value.allow_static_credentials, false)
  aws_access_key_id        = each.value.kind == "AWS_STATIC" ? module.aws_static[each.key].access_key_id : null
  aws_secret_access_key    = each.value.kind == "AWS_STATIC" ? module.aws_static[each.key].secret_access_key : null
  aws_region               = each.value.kind == "AWS_STATIC" ? var.aws_region : null
  azure_tenant_id          = contains(["AZURE_STATIC", "AZURE_OIDC"], each.value.kind) ? (each.value.kind == "AZURE_STATIC" ? module.azure_static[each.key].tenant_id : module.azure_oidc[each.key].tenant_id) : null
  azure_subscription_id    = contains(["AZURE_STATIC", "AZURE_OIDC"], each.value.kind) ? (each.value.kind == "AZURE_STATIC" ? module.azure_static[each.key].subscription_id : module.azure_oidc[each.key].subscription_id) : null
  azure_client_id          = contains(["AZURE_STATIC", "AZURE_OIDC"], each.value.kind) ? (each.value.kind == "AZURE_STATIC" ? module.azure_static[each.key].client_id : module.azure_oidc[each.key].client_id) : null
  azure_client_secret      = each.value.kind == "AZURE_STATIC" ? module.azure_static[each.key].client_secret_value : null
  aws_role_arn             = each.value.kind == "AWS_RBAC" ? module.aws_rbac[each.key].iam_role_arn : each.value.kind == "AWS_OIDC" ? module.aws_oidc[each.key].oidc_role_arn : null
  aws_external_id          = each.value.kind == "AWS_RBAC" ? each.value.aws_external_id : null
  gcp_config_file_content  = each.value.kind == "GCP_OIDC" ? module.gcp_oidc[each.key].external_account_config : null
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
  vcs_connectors   = [for key in keys(var.vcs_connectors) : var.vcs_connectors[key].name]
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
