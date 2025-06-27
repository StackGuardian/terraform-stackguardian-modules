############ StackGuardian credentials ############ 

variable "api_key" {
  type        = string
  description = "Your organization's API key on the StackGuardian Platform"
  sensitive   = true

  validation {
    condition     = can(regex("^sgu_[a-zA-Z0-9]+$", var.api_key))
    error_message = "API key must start with 'sgu_' followed by alphanumeric characters."
  }
}

variable "org_name" {
  type        = string
  description = "Your organization name on StackGuardian Platform"

  validation {
    condition     = length(var.org_name) > 0 && length(var.org_name) <= 50
    error_message = "Organization name must be between 1 and 50 characters."
  }
}

########## StackGuardian Workflow Groups ##########

variable "workflow_groups" {
  type        = list(string)
  description = "List of StackGuardian workflow groups"
  default = null
}
########## StackGuardian AWS Cloud Connector (here with RBAC) ##########

variable "cloud_connectors" {
  type = list(object({
    name                 = string
    connector_type       = string
    role_arn             = string
    aws_role_external_id = string
  }))
  description = "List of cloud connectors to be created"

  default = null
  /*
  [
    {
      name                 = "aws-connector-1"
      connector_type       = "AWS_RBAC"
      role_arn             = "arn:aws:iam::123456789012:role/StackGuardianRole"
      aws_role_external_id = "test-org:1234567"
    }
  ]
  */
}

########## StackGuardian Role ##########

variable "role_name" {
  type        = string
  description = "name of the aws role thats getting created"
  default = null
}

variable "template_list" {
  type        = list(string)
  description = "The list of templates on StackGuardian platform that you want to work with"
  default = []
}

variable "user_or_group" {
  type        = string
  description = "Group or User that should be onboarded"
  default = null
  #Format: sso-auth/email (email in SSO), sso-auth/group-id (Group in SSO), email (Email via local login)
  #Example: "test-org-1/user@stackguardian.com" or "test-org-1/9djhd38cniwje9jde" or "user@stackguardian.com"
}

variable "entity_type" {
  type        = string
  description = "Type of entity that should be onboarded. Valid values: EMAIL or GROUP"
  default = null
}

###########################################
# StackGuardian Connector - AWS Static key
###########################################

variable "aws_access_key_id" {
  type        = string
  description = "your AWS acoount access key"
  default     = null
}

variable "aws_secret_access_key" {
  type        = string
  description = "your AWS account secret access key"
  default     = null
}

variable "aws_default_region" {
  type        = string
  description = "any default region you want to set, for all your deployments"
  default     = null
}

###########################################
# StackGuardian Connector - Azure Service Principal with Secret
###########################################

variable "armTenantId" {
  type        = string
  description = "your azure account tenant id"
  default     = null
}

variable "armSubscriptionId" {
  type        = string
  description = "your azure subscription id"
  default     = null
}

variable "armClientId" {
  type        = string
  description = "your azure client id"
  default     = null
}

variable "armClientSecret" {
  type        = string
  description = "your azure client secret"
  default     = null
}

###########################################
# StackGuardian Connector - VCS Connectors
###########################################

variable "vcs_connectors" {
  type        = map(any)
  description = "List of version control systems"
  default = null
  /*{
    vcs_bitbucket = {
      kind = "BITBUCKET_ORG"
      name = "bitbucket-connector"
      config = [{
        bitbucket_creds = {
          bitbucket_creds = ""
        }
      }]
    }
  } 
  */
}

/*
########### AWS OIDC ############
# Create a OIDC in AWS IAM and a connected Role for StackGuardian #

variable "account_number" {
  type = number
  description = "AWS account number"
}
variable "region" {
  type = string
  description = "aws region on which you want to create the role"
}
variable "aws_policy" {
  type = string
  description = "ARN of aws policy"
}
*/