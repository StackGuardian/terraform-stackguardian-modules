module "stackguardian_role" {
    source = "../.."
    role_name = var.role_name
    org_name = var.org_name
    allowed_permissions = local.allowed_permissions
}
