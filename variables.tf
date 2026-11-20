variable "policy_assignments" {
  type = map(object({
    name                 = string
    scope                = string
    policy_definition_id = string
    description          = optional(string)
    display_name         = optional(string)
  }))
  default = {}
}
