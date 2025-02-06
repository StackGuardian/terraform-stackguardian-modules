variable "api_key" {
  type = string
  description = "Your organization's API key on the StackGuardian Platform"
}

variable "org_name" {
  type = string
  description = "Your organization name on StackGuardian Platform"
}

variable "connector_type" {
  type = string
  description = "type of connector. You can select anyone of the following AWS_STATIC, AWS_RBAC, AWS_OIDC, AZURE_STATIC, AZURE_OIDC, GCP_STATIC"
}

variable "cloud_connector_name" {
 type = string
  description = "Name of the Cloud connector"
}


################
# AWS_STATIC Credentials
################

variable "aws_access_key_id" {
  type = string
  description = "your AWS acoount access key"
   default = null
}

variable "aws_secret_access_key" {
  type = string
  description = "your AWS account secret access key"
   default = null
}

variable "aws_default_region" {
  type = string
  description = "any default region you want to set, for all your deployments"
   default = null
}

################
# AZURE_STATIC Credentials
################

variable "armTenantId" {
  type = string
  description = "your azure account tenant id"
   default = null

}

variable "armSubscriptionId" {
  type = string
  description = "your azure subscription id"
  default = null
  
}

variable "armClientId" {
  type = string
  description = "your azure client id"
   default = null

}

variable "armClientSecret" {
  type = string
  description = "your azure client secret"
 default = null
}

################
# AWS_OIDC Credentials + AWS_RBAC Credentials
################
variable "role_arn" {
  type = string
  description = "arn of the aws oidc role"
}

###### for AWS_RBAC the externalID is also needed
variable "role_external_id" {
  type = string
  description = "external id of the aws rbac role"
  #default = "<org_name>:<random_string>"
}
