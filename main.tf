module "stackguardian_workflow_group" {
  for_each            = toset(var.workflow_groups)
  source              = "./stackguardian_workflow_group"
  workflow_group_name = each.value
}

locals {
  aws_provider_region = try([
    for connector in values(var.cloud_connectors) : coalesce(connector.aws_region, "eu-central-1")
    if contains(["AWS_STATIC", "AWS_RBAC", "AWS_OIDC"], connector.kind)
  ][0], "eu-central-1")
  has_gcp_connector = anytrue([for connector in values(var.cloud_connectors) : connector.kind == "GCP_OIDC"])
}

# Terraform 1.5 cannot express cross-variable validation. This resource makes
# collection-wide violations hard plan failures rather than advisory checks.
resource "terraform_data" "validate_onboarding" {
  input = {
    cloud_connector_keys = keys(var.cloud_connectors)
    vcs_connector_keys   = nonsensitive(keys(var.vcs_connectors))
  }

  lifecycle {
    precondition {
      condition     = length(setintersection(toset(keys(var.cloud_connectors)), toset(nonsensitive(keys(var.vcs_connectors))))) == 0
      error_message = "cloud_connectors and vcs_connectors must not use the same key."
    }
  }
}

module "aws_rbac" {
  for_each = { for name, connector in var.cloud_connectors : name => connector if connector.kind == "AWS_RBAC" }

  source = "./aws_rbac"

  iam_role_name       = each.value.iam_role_name
  role_external_id    = each.value.aws_external_id
  policy_arn          = coalesce(each.value.policy_arn, "arn:aws:iam::aws:policy/ReadOnlyAccess")
  trusted_account_ids = coalesce(each.value.trusted_account_ids, ["476299211833", "163602625436"])
}

module "aws_static" {
  for_each = { for name, connector in var.cloud_connectors : name => connector if connector.kind == "AWS_STATIC" }

  source = "./aws_static"

  aws_region               = coalesce(each.value.aws_region, "eu-central-1")
  iam_user                 = coalesce(each.value.iam_user_name, each.key)
  allow_static_credentials = each.value.allow_static_credentials
}

module "aws_oidc" {
  for_each = { for name, connector in var.cloud_connectors : name => connector if connector.kind == "AWS_OIDC" }

  source = "./aws_oidc"

  aws_region             = coalesce(each.value.aws_region, "eu-central-1")
  iam_role_name          = each.value.iam_role_name
  stackguardian_org_name = var.stackguardian_org_name
  policy_arn             = coalesce(each.value.policy_arn, "arn:aws:iam::aws:policy/ReadOnlyAccess")
}

module "azure_oidc" {
  for_each = { for name, connector in var.cloud_connectors : name => connector if connector.kind == "AZURE_OIDC" }

  source = "./azure_oidc"

  subscription_id          = each.value.azure_subscription_id
  tenant_id                = each.value.azure_tenant_id
  application_display_name = coalesce(each.value.application_display_name, each.key)
  stackguardian_org_name   = var.stackguardian_org_name
  role_definition_name     = coalesce(each.value.role_definition_name, "Contributor")
}

module "azure_static" {
  for_each = { for name, connector in var.cloud_connectors : name => connector if connector.kind == "AZURE_STATIC" }

  source = "./azure_static"

  subscription_id          = each.value.azure_subscription_id
  tenant_id                = each.value.azure_tenant_id
  application_display_name = coalesce(each.value.application_display_name, each.key)
  role_definition_name     = coalesce(each.value.role_definition_name, "Contributor")
  allow_static_credentials = each.value.allow_static_credentials
}

module "gcp_oidc" {
  for_each = { for name, connector in var.cloud_connectors : name => connector if connector.kind == "GCP_OIDC" }

  source = "./gcp_oidc"

  project_id                          = each.value.gcp_project_id
  stackguardian_org_name              = var.stackguardian_org_name
  service_account_id                  = each.value.gcp_service_account_id
  workload_identity_pool_id           = each.value.gcp_workload_pool_id
  workload_identity_pool_provider_id  = each.value.gcp_provider_id
  workload_identity_pool_display_name = each.key
  project_role                        = coalesce(each.value.gcp_project_role, "roles/owner")
}

module "stackguardian_connector_cloud" {
  for_each = var.cloud_connectors

  source                   = "./stackguardian_connector_cloud"
  connector_name           = each.key
  connector_kind           = each.value.kind
  allow_static_credentials = coalesce(each.value.allow_static_credentials, false)
  aws_access_key_id        = each.value.kind == "AWS_STATIC" ? module.aws_static[each.key].access_key_id : null
  aws_secret_access_key    = each.value.kind == "AWS_STATIC" ? module.aws_static[each.key].secret_access_key : null
  aws_region               = each.value.kind == "AWS_STATIC" ? coalesce(each.value.aws_region, "eu-central-1") : null
  azure_tenant_id          = contains(["AZURE_STATIC", "AZURE_OIDC"], each.value.kind) ? each.value.azure_tenant_id : null
  azure_subscription_id    = contains(["AZURE_STATIC", "AZURE_OIDC"], each.value.kind) ? each.value.azure_subscription_id : null
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
  for_each = var.roles

  source           = "./stackguardian_role"
  org_name         = var.stackguardian_org_name
  role_name        = each.key
  workflow_groups  = [for name in each.value.workflow_groups : module.stackguardian_workflow_group[name].workflow_groups]
  cloud_connectors = [for name in each.value.cloud_connectors : module.stackguardian_connector_cloud[name].connector_name]
  vcs_connectors   = [for name in each.value.vcs_connectors : nonsensitive(module.stackguardian_connector_vcs.connector_vcs[index(nonsensitive(keys(var.vcs_connectors)), name)])]
  template_list    = each.value.template_list
}

module "stackguardian_role_assignment" {
  for_each = var.subjects

  source      = "./stackguardian_role_assignment"
  roles       = [for name in each.value.roles : module.stackguardian_role[name].role]
  subject     = each.key
  entity_type = each.value.entity_type
}
