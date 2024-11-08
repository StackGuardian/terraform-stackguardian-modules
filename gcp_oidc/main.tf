#StackGuardian OIDC Connector
locals {
  sg-org-id = var.sg-org-id
}

# Create Service Account
resource "google_service_account" "sg-service-account" {
  account_id   = var.service_account_id
  display_name = "StackGuardian Service Account"
}


resource "google_iam_workload_identity_pool" "sg-pool" {
  workload_identity_pool_id = var.workload_identity_pool_id
}

resource "google_iam_workload_identity_pool_provider" "sg-oidc-connector-provider-x" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.sg-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_pool_provider_id
  display_name                       = var.workload_identity_pool_display_name
  description                        = "OIDC identity pool provider for StackGuardian Connector"
  disabled                           = false
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["https://testapi.qa.stackguardian.io"] # https://api.app.stackguardian.io
    issuer_uri        = "https://testapi.qa.stackguardian.io"
  }
}


# Allow Service Account Impersonation via Federation
resource "google_service_account_iam_member" "allow_federation_impersonation" {
  service_account_id = google_service_account.sg-service-account.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/projects/${google_iam_workload_identity_pool.sg-pool.project}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.sg-pool.workload_identity_pool_id}/subject//orgs/${local.sg-org-id}"
}

# Assign Policy for Federated Identity
resource "google_service_account_iam_policy" "federated_identity" {
  service_account_id = google_service_account.sg-service-account.name

  policy_data = <<EOF
{
  "bindings": [
    {
      "role": "roles/iam.workloadIdentityUser",
      "members": [
        "serviceAccount:${google_service_account.sg-service-account.email}"
      ]
    }
  ]
}
EOF
}

# Grant the Service Account the necessary permissions
resource "google_project_iam_member" "sg-service-account-iam" {
  project = google_iam_workload_identity_pool.sg-pool.project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.sg-service-account.email}"
}
# Download the Client Library Configuration File, use token path /mnt/sg_workspace/user/stackguardian.oidc