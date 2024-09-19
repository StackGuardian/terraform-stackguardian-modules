resource "stackguardian_connector_vcs" "sg_vcs_connector" {
  data = jsonencode({
    "ResourceName" : var.vcs_connector_name
    "Tags" : ["tf-provider-example", "onboarding"]
    "Description" : "Onboarding of VCS Connector",
    "Settings" : {
      "kind" : var.vcs_kind
      "config" : [ var.gitlab_credentials]
    },
  })
}