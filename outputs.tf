output "role_permissions" {
  description = "Generated permission documents keyed by role name."
  value       = { for name, role in module.stackguardian_role : name => role.allowed_permissions }
}

output "subject_roles" {
  description = "Assigned role names keyed by subject."
  value       = { for subject, assignment in module.stackguardian_role_assignment : subject => assignment.roles }
}
