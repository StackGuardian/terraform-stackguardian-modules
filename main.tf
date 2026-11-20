module "policy_assignment" {
  source   = "./modules/policy_assignment"
  for_each = var.policy_assignments

  name                 = each.value.name
  scope                = each.value.scope
  policy_definition_id = each.value.policy_definition_id
  description          = each.value.description
  display_name         = each.value.display_name
}
