variable "connector" {
  type = string
  default = "aws-connector"
  description = "Name for this AWS Connector in the StackGuardian platform"
}
variable "awsaccesskeyid" {
  type = string
  default = ""
}
variable "awssecretaccesskey" {
  type = string
  default = ""
}
variable "region" {
  type = string
  default = "eu-central-1"
}
variable "api_key" {
  type = string
  description = "API key to authenticate to StackGuardian"
}
variable "org_name" {
  type = string
  description = "Organisation name in StackGuardian platform"
}
