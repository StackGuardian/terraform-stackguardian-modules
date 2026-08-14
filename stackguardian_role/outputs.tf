output "role" {
  description = "Created Role"
  value       = var.role_name
}

output "allowed_permissions" {
  description = "Generated StackGuardian role v4 permission document."
  value       = local.team_onboarding_permissions
}
