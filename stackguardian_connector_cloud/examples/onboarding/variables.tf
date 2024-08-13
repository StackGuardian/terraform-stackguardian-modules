variable "connector" {
  type = string
}
variable "awsaccesskey" {
  type = string
}
variable "awssecretaccesskey" {
  type = string
}
variable "region" {
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