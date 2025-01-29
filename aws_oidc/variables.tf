variable "region" {
  type = string
  description = "the region for deploying the resources"
}

variable "url" {
  type = string
  description = "URL of the identity provider"
}

variable "client_id" {
  type = string
  description = "List of client IDs (audiences) that identify the application registered with the OpenID Connect provider" 
}

variable "role_name" {
  type = string
  description = "name of the aws role thats getting created"
}

variable "org_name" {
  type = string
  description = "the name of the StackGuardian Organization"
}

variable "account_number" {
  type = number
  description = "the value of the account number"
}

variable "aws_policy" {
  type = string
  description = "arn od aws policy"
}
