resource "stackguardian_role_assignment" "sg_user" {
  user_id     = var.subject
  entity_type = var.entity_type
  roles       = var.roles
}
