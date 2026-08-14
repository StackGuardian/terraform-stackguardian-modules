locals {
  oidc_subject = coalesce(var.oidc_subject, "/orgs/${var.stackguardian_org_name}")
}

moved {
  from = google_service_account.sg-service-account
  to   = google_service_account.stackguardian
}

moved {
  from = google_iam_workload_identity_pool.sg-pool
  to   = google_iam_workload_identity_pool.stackguardian
}

moved {
  from = google_iam_workload_identity_pool_provider.sg-oidc-connector-provider-x
  to   = google_iam_workload_identity_pool_provider.stackguardian
}

moved {
  from = google_service_account_iam_member.allow_federation_impersonation
  to   = google_service_account_iam_member.federation_impersonation
}

moved {
  from = google_project_iam_member.sg-service-account-iam
  to   = google_project_iam_member.stackguardian
}

resource "google_service_account" "stackguardian" {
  account_id   = var.service_account_id
  display_name = "StackGuardian Service Account"
  description  = "Service account used by StackGuardian workload identity federation."
  project      = var.project_id
}

resource "google_iam_workload_identity_pool" "stackguardian" {
  workload_identity_pool_id = var.workload_identity_pool_id
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "stackguardian" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.stackguardian.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_pool_provider_id
  display_name                       = var.workload_identity_pool_display_name
  description                        = "OIDC identity pool provider for StackGuardian."
  project                            = var.project_id
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = var.oidc_allowed_audiences
    issuer_uri        = var.oidc_issuer_uri
  }
}

resource "google_service_account_iam_member" "federation_impersonation" {
  service_account_id = google_service_account.stackguardian.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${google_iam_workload_identity_pool.stackguardian.project}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.stackguardian.workload_identity_pool_id}/subject/${local.oidc_subject}"
}

# Import the pre-existing self-member binding before removing the former authoritative policy state.
resource "google_service_account_iam_member" "self_workload_identity" {
  service_account_id = google_service_account.stackguardian.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${google_service_account.stackguardian.email}"
}

resource "google_project_iam_member" "stackguardian" {
  project = var.project_id
  role    = var.project_role
  member  = "serviceAccount:${google_service_account.stackguardian.email}"
}
