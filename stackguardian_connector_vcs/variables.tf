variable "api_key" {
  type = string
  description = "API key to authenticate to StackGuardian"
}
variable "org_name" {
  type = string
  description = "Organisation name in StackGuardian platform"
}

variable "vcs_connectors" {
  description = "A map of connectors and their respective configurations"
  type = map(any)
  default = {
    vcs_gitlab = {
      kind   = "GITLAB_COM"
      name   = "gitlab-connector"
      config = [{
        gitlab_creds = {
            gitlabCreds =  "gitlabuser:gitlab_pat",
            gitlabHttpUrl =  "https://gitlab.com",
            gitlabApiUrl =  "https://gitlab.com/api/v4"
        }
      }]
    },
    vcs_github = {
      name   = "github-connector"
      kind   = "GITHUB_COM"
      config = [{
        github_creds = {
          githubCreds     = "username:personal_access_token"
          github_com_url  = "https://api.github.com"
          github_http_url = "https://github.com"
        }
      }]
    },
    vcs_bitbucket = {
      name   = "bitbucket-connector"
      kind   = "BITBUCKET_ORG"
      config = [{
        bitbucket_creds = {
          bitbucket_creds = ""
        }
      }]
    }
  }
}
