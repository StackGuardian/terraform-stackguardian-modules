variable "api_key" {
  type = string
  description = "value of the api key for the StackGuardian platform"
}
variable "org_name" {
  type = string
  description = "name of the organization on StackGuardian that you want to work with"
}
variable "workflow_group" {
  type = list
  description = "the list of workflow groups"
}
variable "cloud_connector" {
  type = list
  description = "list of cloud connectors you want to work with"
}
variable "stackguardian_connector_vcs" {
  type = list
  description = "list of version control systems"
}
variable "template_list" {
  type = list
  description = "the list of templates on StackGuardian that you want to work with"
}
variable "allowed_permissions" {
  type = any
  description = "the type of permissions you want to provide to the user"
  default = {
      "Permission-key-1" : "Permission-val-1",
      "Permission-key-2" : "Permission-val-2"
    }
}

variable "role_name" {
  type = string
  description = "name of the role"
}