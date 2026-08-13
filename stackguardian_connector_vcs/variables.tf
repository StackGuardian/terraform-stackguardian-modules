variable "vcs_connectors" {
  description = "Typed VCS connector configuration. Credentials remain in Terraform state."
  sensitive   = true
  type = map(object({
    kind = string
    name = string
    github = optional(object({
      githubCreds     = string
      github_com_url  = optional(string, "https://api.github.com")
      github_http_url = optional(string, "https://github.com")
    }))
    gitlab = optional(object({
      gitlabCreds   = string
      gitlabHttpUrl = optional(string, "https://gitlab.com")
      gitlabApiUrl  = optional(string, "https://gitlab.com/api/v4")
    }))
    bitbucket = optional(object({
      bitbucket_creds = string
    }))
  }))

  validation {
    condition = alltrue([for connector in values(var.vcs_connectors) :
      length(trimspace(connector.name)) > 0 && (
        (connector.kind == "GITHUB_COM" && connector.github != null && connector.gitlab == null && connector.bitbucket == null && length(trimspace(connector.github.githubCreds)) > 0) ||
        (connector.kind == "GITLAB_COM" && connector.gitlab != null && connector.github == null && connector.bitbucket == null && length(trimspace(connector.gitlab.gitlabCreds)) > 0) ||
        (connector.kind == "BITBUCKET_ORG" && connector.bitbucket != null && connector.github == null && connector.gitlab == null && length(trimspace(connector.bitbucket.bitbucket_creds)) > 0)
      )
    ])
    error_message = "Each VCS connector needs a non-empty, matching GitHub, GitLab, or Bitbucket credential object."
  }
}
