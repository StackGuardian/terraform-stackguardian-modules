variable "stackguardian_connector_vcs_name" {
  type = string
  description = "name of the connector"
}
variable "api_key" {
  type = string
  description = "API key to authenticate to StackGuardian"
}
variable "org_name" {
  type = string
  description = "Organisation name in StackGuardian platform"
}

variable "stackguardian_connector_kinds" {
  description = "A map of connector kinds and their respective configurations"
  type = map(any)
  default = {
    vcs_gitlab = {
      kind   = "GITLAB_COM"
      config = [{
        gitlab_creds = {
            gitlabCreds =  "gitlabuser:gitlab_pat",
            gitlabHttpUrl =  "https://gitlab.com",
            gitlabApiUrl =  "https://gitlab.com/api/v4"
        }
      }]
    },
    vcs_github = {
      kind   = "GITHUB_COM"
      config = [{
        github_creds = {
          github_com_url = ""
          github_http_url = ""
        }
      }]
    },
    vcs_bitbucket = {
      kind   = "BITBUCKET_ORG"
      config = [{
        bitbucket_creds = {
          bitbucket_creds = ""
        }
      }]
    }
  }
}
