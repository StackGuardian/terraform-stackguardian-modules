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

output "external_account_config" {
  description = "External account configuration registered with the StackGuardian GCP OIDC connector."
  value = jsonencode({
    type                              = "external_account"
    audience                          = "//iam.googleapis.com/${google_iam_workload_identity_pool.stackguardian.name}/providers/${google_iam_workload_identity_pool_provider.stackguardian.workload_identity_pool_provider_id}"
    subject_token_type                = "urn:ietf:params:oauth:token-type:jwt"
    token_url                         = "https://sts.googleapis.com/v1/token"
    service_account_impersonation_url = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${google_service_account.stackguardian.email}:generateAccessToken"
  })
}
