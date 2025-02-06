variable "region" {
  type = string
  description = "the region for deploying the resources"
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
  description = "arn of aws policy"
}
