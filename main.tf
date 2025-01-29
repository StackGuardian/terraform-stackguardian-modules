# ################################
#  # Stackguardian Workflow Group
# ################################
module "stackguardian_workflow_group" {
  source = "../terraform-stackguardian-modules/stackguardian_workflow_group"
  api_key = var.api_key
  org_name = var.org_name
  workflow_group_name = var.workflow_group_name
}

# ################################
#  # Stackguardian aws oidc
# ################################
module "aws_oidc" {
  source = "../terraform-stackguardian-modules/aws_oidc"
  account_number = var.account_number
  client_id = var.client_id
  region = var.region
  aws_policy = var.aws_policy
  role_name = var.role_name
  url = var.url
  org_name = var.org_name
}

# ################################
#  # Stackguardian cloud connector
# ################################
module "stackguardian_connector_cloud" {
  source = "../terraform-stackguardian-modules/stackguardian_connector_cloud"
  cloud_connector_name = var.cloud_connector_name
  connector_type = var.connector_type
  api_key = var.api_key
  org_name = var.org_name

  role_arn = module.aws_oidc.oidc_role_arn

  aws_access_key_id = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_default_region = var.aws_default_region

  armTenantId = var.armTenantId
  armSubscriptionId = var.armSubscriptionId
  armClientId = var.client_id
  armClientSecret = var.armClientSecret
}

################################
 # Stackguardian vcs
################################
locals {
  # Determine which VCS connector to create based on non-empty credentials
  selected_connector = merge(
    # If GitLab creds are provided, use GitLab connector
    length(var.gitlab_creds) > 0 ? {
      vcs_gitlab = {
        kind   = "GITLAB_COM"
        config = [{
          gitlab_creds = var.gitlab_creds
        }]
      }
    } : {},

    # If GitHub creds are provided, use GitHub connector
    length(var.github_creds) > 0 ? {
      vcs_github = {
        kind   = "GITHUB_COM"
        config = [{
          github_creds = var.github_creds
        }]
      }
    } : {},

    # If Bitbucket creds are provided, use Bitbucket connector
    length(var.bitbucket_creds) > 0 ? {
      vcs_bitbucket = {
        kind   = "BITBUCKET_COM"
        config = [{
          bitbucket_creds = var.bitbucket_creds
        }]
      }
    } : {}
  )
}

module "stackguardian_connector_vcs" {
  source = "../terraform-stackguardian-modules/stackguardian_connector_vcs"
  stackguardian_connector_vcs_name = var.stackguardian_connector_vcs_name
  api_key = var.api_key
  org_name = var.org_name
  stackguardian_connector_kinds      = local.selected_connector
}

################################
 # Stackguardian role
################################
module "stackguardian_role" {
  source = "../terraform-stackguardian-modules/stackguardian_role"
  api_key = var.api_key
  org_name = var.org_name
  role_name = var.role_name
  cloud_connector = var.cloud_connector
  stackguardian_connector_vcs = var.stackguardian_connector_vcs
  workflow_group = var.workflow_group
  template_list = var.template_list
  #depends_on = [ module.stackguardian_workflow_group, module.stackguardian_connector_cloud, module.stackguardian_connector_vcs ]
}

# ################################
#  # Stackguardian role assignment
# ################################
module "stackguardian_role_assignment" {
  source = "../terraform-stackguardian-modules/stackguardian_role_assignment"
  api_key = var.api_key
  org_name = var.org_name
  role_name = var.role_name
  user_or_group = var.user_or_group
  entity_type = var.entity_type
}