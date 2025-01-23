variable "region" {
  type = string
  description = "the region for deploying the resources"
  default = "eu-central-1"
}

variable "url" {
  type = string
  description = "URL of the identity provider"
  default = "https://api.app.stackguardian.io"
}

variable "client_id" {
  type = string
  description = "List of client IDs (audiences) that identify the application registered with the OpenID Connect provider"
  default =  "https://api.app.stackguardian.io" 
}

variable "role_name" {
  type = string
  description = "name of the aws role thats getting created"
  default = "test-clara-001"
}

variable "org_name" {
  type = string
  description = "the name of the StackGuardian Organization"
  default = "wicked-hop"
}

variable "account_number" {
  type = number
  description = "the value of the account number"
  default = 790543352839
}

