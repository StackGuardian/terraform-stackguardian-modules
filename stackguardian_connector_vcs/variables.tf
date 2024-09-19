variable "vcs_connector_name" {
  type = string
}
variable "api_key" {
  type = string
  description = "API key to authenticate to StackGuardian"
}
variable "org_name" {
  type = string
  description = "Organisation name in StackGuardian platform"
}
variable "vcs_kind" {
  type = string
  default = "GITLAB_COM" # GITHUB_COM, GITHUB_APP_CUSTOM, BITBUCKET_ORG, AZURE_DEVOPS
}




##########Gitlab credentials #####

variable "gitlab_credentials" {
  type = any
  default = {
    
            "gitlabCreds": "gitlabuser:gitlab_pat",
            "gitlabHttpUrl": "https://gitlab.com",
            "gitlabApiUrl": "https://gitlab.com/api/v4"
        
  }
}