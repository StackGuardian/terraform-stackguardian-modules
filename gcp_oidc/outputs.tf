output "service_account_email" {
  description = "Email of the StackGuardian service account."
  value       = google_service_account.stackguardian.email
}

output "workload_identity_pool_id" {
  description = "ID of the workload identity pool."
  value       = google_iam_workload_identity_pool.stackguardian.workload_identity_pool_id
}

output "workload_identity_pool_provider_id" {
  description = "ID of the StackGuardian OIDC workload identity provider."
  value       = google_iam_workload_identity_pool_provider.stackguardian.workload_identity_pool_provider_id
}
