resource "stackguardian_connector" "sg_vcs_connector" {
  resource_name = var.resource_name
  description   = "Onboarding example of terraform-provider-stackguardian for ConnectorVcs"
 settings = {
    kind = var.vcs_kind
    config = [{
      gitlab_creds = var.gitlab_credentials
    }]
  }
}