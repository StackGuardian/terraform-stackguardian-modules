variable "region" {
  type = string
  description = "aws region on which you want to create the role"
}

variable "api_key" {
  type = string
  description = "Your organization's API key on the StackGuardian Platform"
}

variable "org_name" {
  type = string
  description = "Your organization name on StackGuardian Platform"
}

variable "workflow_group_name" {
  type = string
  description = "StackGuardian workflow group name"
}

variable "account_number" {
  type = number
  description = "AWS account number"
}

variable "url" {
  type = string
  description = "URL of the identity provider"
}

variable "client_id" {
  type = string
  description = "client IDs (audiences) that identify the application registered with the OpenID Connect provider"
  default = "https://api.app.stackguardian.io"
}

variable "role_name" {
  type = string
  description = "name of the aws role thats getting created"
}

variable "aws_policy" {
  type = string
  description = "ARN of aws policy"
}

variable "cloud_connector_name" {
  type = string
  description = "StackGuardian Cloud connector name"
}

variable "connector_type" {
  type = string
  description = "type of connector. You can select anyone of the following AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, GCP_STATIC"
}

###########################################
# AWS Connector
#
# To set these variables, please use environment variables:
# export "TF_VAR_aws_access_key=xxxx"
# export "TF_VAR_aws_secret_key=your-aws-secret-key"
###########################################

variable "aws_access_key_id" {
  type = string
  description = "your AWS acoount access key"
}

variable "aws_secret_access_key" {
  type = string
  description = "your AWS account secret access key"
}

variable "aws_default_region" {
  type = string
  description = "any default region you want to set, for all your deployments"
}

###########################################
# Azure Connector
#
# To set these variables, please use environment variables:
# export "TF_VAR_client_id=xxxx-yyyy-rrrr-fff"
# export "TF_VAR_client_secret=your-client-secret"
# export "TF_VAR_tenant_id=your-tenant-id"
###########################################

variable "armTenantId" {
  type = string
  description = "your azure account tenant id"
}

variable "armSubscriptionId" {
  type = string
  description = "your azure subscription id"
}

variable "armClientId" {
  type = string
  description = "your azure client id"
}

variable "armClientSecret" {
  type = string
  description = "your azure client secret id"
}

variable "stackguardian_connector_vcs_name" {
  type = string
  description = "StackGuardian connector vcs name"
}

variable "workflow_group" {
  type = list
  description = "the list of workflow groups for the stackguardian role"
}

variable "cloud_connector" {
  type = list
  description = "list of cloud connectors for the stackguardian role"
}
variable "stackguardian_connector_vcs" {
  type = list
  description = "list of version control systems for the stackguardian role"
}

variable "template_list" {
  type = list
  description = "the list of templates on StackGuardian platform that you want to work with"
}

variable "user_or_group" {
  type = string
  description = "Group or User that should be onboarded" 
  #Format: sso-auth/email (email in SSO), sso-auth/group-id (Group in SSO), email (Email via local login)
  #Example: "stackguardian-1/user@stackguardian.com" or "stackguardian-1/9djhd38cniwje9jde" or "user@stackguardian.com"
}

variable "entity_type" {
  type = string
  description = "Type of entity that should be onboarded. Valid values: EMAIL or GROUP"
}

variable "stackguardian_connector_kinds" {
  description = "A map of connector kinds and their respective configurations"
  type = map(any)
  default = {
    vcs_gitlab = {
      kind   = "GITLAB_COM"
      config = [{
        gitlab_creds = {
            gitlabCreds =  "",
            gitlabHttpUrl = "",
            gitlabApiUrl = ""
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

variable "gitlab_creds" {
  description = "GitLab credentials"
  type        = map(string)
  default     = {}
}

# Credentials for GitHub
variable "github_creds" {
  description = "GitHub credentials"
  type        = map(string)
  default     = {}
}

# Credentials for Bitbucket
variable "bitbucket_creds" {
  description = "Bitbucket credentials"
  type        = map(string)
  default     = {}
}
