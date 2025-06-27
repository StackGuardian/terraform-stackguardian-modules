locals {
  cloud_connectors_list = [for con in var.cloud_connectors : con.name]
}

# ################################
#  # Create Stackguardian Workflow Group
# ################################
module "stackguardian_workflow_group" {
  for_each             = var.workflow_groups != null ? toset(var.workflow_groups) : []
  source              = "./stackguardian_workflow_group"
  api_key             = var.api_key
  org_name            = var.org_name
  workflow_group_name = each.key
}

# ################################
#  # Create Stackguardian cloud connector
# ################################
module "stackguardian_connector_cloud" {
  for_each             = var.cloud_connectors != null ? { for c in var.cloud_connectors : c.name => c } : {}
  source               = "./stackguardian_connector_cloud"
  cloud_connector_name = each.key
  connector_type       = each.value.connector_type
  role_arn             = each.value.role_arn
  role_external_id     = each.value.aws_role_external_id
  api_key              = var.api_key
  org_name             = var.org_name
}

################################
# Create Stackguardian VCS Connector
################################


module "vcs_connector" {
  count          = var.vcs_connectors != null ? 1 : 0
  source         = "./stackguardian_connector_vcs"
  vcs_connectors = var.vcs_connectors
  api_key        = var.api_key
  org_name       = var.org_name
}


################################
# Create Stackguardian Role
################################
module "stackguardian_role" {
  count            = var.role_name != null ? 1 : 0
  source           = "./stackguardian_role"
  api_key          = var.api_key
  org_name         = var.org_name
  role_name        = var.role_name
  cloud_connectors = [for con in var.cloud_connectors : con.name]
  vcs_connectors   = [for vcs in var.vcs_connectors : vcs.name]
  workflow_groups  = var.workflow_groups
  template_list    = var.template_list
  #depends_on = [ module.stackguardian_workflow_group, module.stackguardian_connector_cloud, module.stackguardian_connector_vcs ]
}

# ################################
#  # Create Stackguardian role assignment
# ################################
module "stackguardian_role_assignment" {
  count         = var.user_or_group != null ? 1 : 0
  source        = "./stackguardian_role_assignment"
  api_key       = var.api_key
  org_name      = var.org_name
  role_name     = var.role_name
  user_or_group = var.user_or_group
  entity_type   = var.entity_type
  depends_on    = [module.stackguardian_role]
}
