variable "api_key" {
  type        = string
  description = "Your organization's API key on the StackGuardian Platform"
  sensitive   = true
}

variable "org_name" {
  type        = string
  description = "Your organization name on StackGuardian Platform"
}

variable "sg_api_uri" {
  type        = string
  description = "Your organization name on StackGuardian Platform"
}

variable "vcs_connectors" {
  type        = string
  description = "type of vcs connector. You can select anyone of the following GITHUB_COM, GITHUB_APP_CUSTOM, BITBUCKET_ORG, GITLAB_COM, AZURE_DEVOPS"
  validation {
    condition = contains([
      "GITHUB_COM",
      "GITHUB_APP_CUSTOM",
      "BITBUCKET_ORG",
      "GITLAB_COM",
      "AZURE_DEVOPS"
    ], var.vcs_connectors)
    error_message = "Variable vcs_connectors must be one of GITHUB_COM, GITHUB_APP_CUSTOM, BITBUCKET_ORG, GITLAB_COM, AZURE_DEVOPS."
  }
}

variable "vcs_connector_name" {
  type        = string
  description = "Name of the VCS connector"
}


################
# GITHUB_COM Credentials
################

variable "github_com_url" {
  type        = string
  description = "github URL for accessing the GitHub website."
  default     = null # optional
}

variable "github_http_url" {
  type        = string
  description = "HTTP URL for accessing the GitHub repository"
  default     = null # optional
}

################
# GITHUB_APP_CUSTOM Credentials
################

variable "github_app_client_id" {
  type        = string
  description = "GitHub App client ID"
  default     = null # optional
}

variable "github_app_client_secret" {
  type        = string
  description = "GitHub App client secret"
  default     = null # optional
  sensitive   = true
}

variable "github_app_id" {
  type        = string
  description = "GitHub App ID"
  default     = null # optional
}

variable "github_app_pem_file_content" {
  type        = string
  description = "GitHub App PEM file content"
  default     = null # optional
  sensitive   = true
}

variable "github_app_webhook_secret" {
  type        = string
  description = "GitHub App webhook secret"
  default     = null # optional
  sensitive   = true
}

variable "github_app_webhook_url" {
  type        = string
  description = "GitHub App webhook URL"
  default     = null # optional
}

################
# BITBUCKET_ORG Credentials
################
variable "bitbucket_creds" {
  type        = string
  description = "Bitbucket credentials"
  sensitive   = true
  default     = null
}

################
# GITLAB_COM Credentials
################

variable "gitlab_api_url" {
  type        = string
  description = "GitLab API URL"
  default     = null
}

variable "gitlab_creds" {
  type        = string
  description = "GitLab credentials"
  sensitive   = true
  default     = null
}

variable "gitlab_http_url" {
  type        = string
  description = "GitLab HTTP URL"
  default     = null
}

################
# AZURE_DEVOPS Credentials
################
variable "azure_devops_api_url" {
  type        = string
  description = "Azure DevOps API URL"
  default     = null
}

variable "azure_devops_http_url" {
  type        = string
  description = "Azure DevOps HTTP URL"
  default     = null
}

variable "azure_creds" {
  type        = string
  description = "Azure DevOps credentials"
  sensitive   = true
  default     = null
}

# variable "aws_secret_access_key" {
#   type        = string
#   description = "your AWS account secret access key"
#   default     = null # optional
#   sensitive   = true
# }

# variable "aws_default_region" {
#   type        = string
#   description = "any default region you want to set, for all your deployments"
#   default     = null # optional
# }

################
# AZURE_STATIC Credentials
################

variable "armTenantId" {
  type        = string
  description = "your azure account tenant id"
  default     = null # optional
}

variable "armSubscriptionId" {
  type        = string
  description = "your azure subscription id"
  default     = null # optional
}

variable "armClientId" {
  type        = string
  description = "your azure client id"
  default     = null # optional
}

variable "armClientSecret" {
  type        = string
  description = "your azure client secret"
  default     = null # optional
  sensitive   = true
}

################
# AWS_OIDC Credentials + AWS_RBAC Credentials
################
variable "role_arn" {
  type        = string
  description = "arn of the aws oidc role"
  default     = null # optional
}

###### for AWS_RBAC the externalID is also needed
variable "role_external_id" {
  type        = string
  description = "external id of the aws rbac role"
  default     = null # optional; "<org_name>:<random_string>" is recommended
}

################
# GCP_OIDC Credentials + GCP_STATIC Credentials
################
variable "gcp_config_file_content" {
  type        = string
  description = "the gco config content gor the connector"
  default     = null # optional
}


# variable "api_key" {
#   type        = string
#   description = "API key to authenticate to StackGuardian"
# }
# variable "org_name" {
#   type        = string
#   description = "Organisation name in StackGuardian platform"
# }
# variable "sg_api_uri" {
#   type        = string
#   description = "Your organization name on StackGuardian Platform"
# }

# variable "vcs_connectors" {
#   description = "A map of connectors and their respective configurations"
#   type        = map(any)
#   default = {
#     vcs_gitlab = {
#       kind = "GITLAB_COM"
#       name = "gitlab-connector"
#       config = [{
#         gitlab_creds = {
#           gitlabCreds   = "gitlabuser:gitlab_pat",
#           gitlabHttpUrl = "https://gitlab.com",
#           gitlabApiUrl  = "https://gitlab.com/api/v4"
#         }
#       }]
#     },
#     vcs_github = {
#       name = "github-connector"
#       kind = "GITHUB_COM"
#       config = [{
#         github_creds = {
#           githubCreds     = "username:personal_access_token"
#           github_com_url  = "https://api.github.com"
#           github_http_url = "https://github.com"
#         }
#       }]
#     },
#     vcs_bitbucket = {
#       name = "bitbucket-connector"
#       kind = "BITBUCKET_ORG"
#       config = [{
#         bitbucket_creds = {
#           bitbucket_creds = ""
#         }
#       }]
#     }
#   }
# }
