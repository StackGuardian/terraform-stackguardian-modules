locals {
  cloud_connectors_list = [for con in var.cloud_connectors : con.name]
}

# ################################
#  # Stackguardian Workflow Group
# ################################
module "stackguardian_workflow_group" {
  for_each = toset(var.workflow_groups)
  source = "./stackguardian_workflow_group"
  api_key = var.api_key
  org_name = var.org_name
  workflow_group_name = each.key
}

# ################################
#  # Stackguardian cloud connector
# ################################
module "stackguardian_connector_cloud" {
  for_each = { for c in var.cloud_connectors : c.name => c }
  source = "./stackguardian_connector_cloud"
  cloud_connector_name = each.key
  connector_type = each.value.connector_type
  role_arn = each.value.role_arn
  role_external_id = each.value.aws_role_external_id
  api_key = var.api_key
  org_name = var.org_name
}

################################
 # Stackguardian vcs
################################
/*
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
*/


module "vcs_connector" {
  source = "./stackguardian_connector_vcs"
  vcs_connectors = var.vcs_connectors
  api_key = var.api_key
  org_name = var.org_name
}


################################
 # Stackguardian role
################################
module "stackguardian_role" {
  source = "./stackguardian_role"
  api_key = var.api_key
  org_name = var.org_name
  role_name = var.role_name
  cloud_connectors = [for con in var.cloud_connectors : con.name]
  vcs_connectors = [for vcs in var.vcs_connectors : vcs.name]
  workflow_groups = var.workflow_groups
  template_list = var.template_list
  #depends_on = [ module.stackguardian_workflow_group, module.stackguardian_connector_cloud, module.stackguardian_connector_vcs ]
}

# ################################
#  # Stackguardian role assignment
# ################################
module "stackguardian_role_assignment" {
  source = "./stackguardian_role_assignment"
  api_key = var.api_key
  org_name = var.org_name
  role_name = var.role_name
  user_or_group = var.user_or_group
  entity_type = var.entity_type
  depends_on = [ module.stackguardian_role ]
}

/*
# ################################
#  # Create OIDC provider and StackGuardian Role in AWS
# ################################
module "aws_oidc" {
  count = var.account_number != null ? 1 : 0
  source = "./aws_oidc"
  account_number = var.account_number
  region = var.region
  aws_policy = var.aws_policy
  role_name = var.role_name
  org_name = var.org_name
}
*/