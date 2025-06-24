# resource "stackguardian_connector" "sg_vcs_connector" {
#   resource_name = var.stackguardian_connector_vcs_name
#   description   = "Onboarding example of terraform-provider-stackguardian for ConnectorVcs"
#  settings = {
#     kind = var.vcs_kind
#     config = [{
#       gitlab_creds = var.gitlab_credentials
#     }]
#   }
# }

resource "stackguardian_connector" "sg_vcs_connector" {
  for_each = {
    for key, value in var.vcs_connectors :
    key => value if(
      # Check if any credentials are provided for gitlab, github or bitbucket
      (
        (lookup(value.config[0], "gitlab_creds", null) != null) ||
        (lookup(value.config[0], "github_creds", null) != null) ||
        (lookup(value.config[0], "bitbucket_creds", null) != null)
      )
    )
  }

  resource_name = each.value.name
  description   = "Onboarding VCS connector"

  settings = {
    kind = each.value.kind
    config = flatten([
      for config_item in each.value.config : {
        # Dynamically handle different connector types and jsonencode here
        gitlab_creds    = lookup(config_item, "gitlab_creds", null) != null ? jsonencode(lookup(config_item, "gitlab_creds", null)) : null
        github_creds    = lookup(config_item, "github_creds", null) != null ? jsonencode(lookup(config_item, "github_creds", null)) : null
        bitbucket_creds = lookup(config_item, "bitbucket_creds", null) != null ? jsonencode(lookup(config_item, "bitbucket_creds", null)) : null
      }
    ])
  }
}