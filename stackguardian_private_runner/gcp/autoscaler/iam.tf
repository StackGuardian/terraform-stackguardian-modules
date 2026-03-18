/*-----------------------+
 | Service Account       |
 +-----------------------*/

# Service Account for Cloud Function
resource "google_service_account" "autoscaler" {
  account_id   = "${local.effective_prefix_lower}-autoscaler"
  display_name = "${local.effective_prefix} Autoscaler"
  project      = var.gcp_project_id
}

/*-----------------------+
 | IAM Bindings          |
 +-----------------------*/

# Allow Cloud Function to manage instance groups (resize MIG)
resource "google_project_iam_member" "autoscaler_compute" {
  project = var.gcp_project_id
  role    = "roles/compute.instanceGroupManagerAdmin"
  member  = "serviceAccount:${google_service_account.autoscaler.email}"
}

# Allow Cloud Function to write logs
resource "google_project_iam_member" "autoscaler_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.autoscaler.email}"
}

# Allow Cloud Function to read/write cooldown state in GCS
resource "google_project_iam_member" "autoscaler_storage" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.autoscaler.email}"
}

# Allow Cloud Scheduler to invoke the Cloud Function (via underlying Cloud Run service)
resource "google_cloud_run_service_iam_member" "autoscaler_invoker" {
  project  = var.gcp_project_id
  location = var.gcp_region
  service  = google_cloudfunctions2_function.autoscaler.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.autoscaler.email}"
}
