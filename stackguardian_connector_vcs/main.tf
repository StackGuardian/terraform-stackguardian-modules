resource "stackguardian_connector_vcs" "sg_vcs_connector" {
  data = jsonencode({
    "ResourceName" : var.vcs_connector
    "ResourceType" : "INTEGRATION.GITLAB_COM",
    "Tags" : ["tf-provider-example", "onboarding"]
    "Description" : "Onboarding example of terraform-provider-stackguardian for ConnectorVcs",
    "Settings" : {
      "kind" : "GITLAB_COM",
      "config" : [
        {
          "gitlabCreds" : var.gitcreds
        }
      ]
    },
  })
}