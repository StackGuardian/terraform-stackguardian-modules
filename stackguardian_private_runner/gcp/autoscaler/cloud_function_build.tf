# Build Cloud Function package from source repository

# Random suffix for globally unique GCS bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# GCS bucket for Cloud Function source code
resource "google_storage_bucket" "function_source" {
  name                        = "${local.effective_prefix_lower}-cf-source-${random_string.bucket_suffix.result}"
  location                    = var.gcp_region
  project                     = var.gcp_project_id
  uniform_bucket_level_access = true
  force_destroy               = true
}

# GCS bucket for autoscaler cooldown state markers
resource "google_storage_bucket" "cooldown_state" {
  name                        = "${local.effective_prefix_lower}-autoscaler-state-${random_string.bucket_suffix.result}"
  location                    = var.gcp_region
  project                     = var.gcp_project_id
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Fetch latest commit hash from remote repo to trigger rebuild on changes
data "external" "repo_commit" {
  program = [
    "sh", "-c",
    "echo \"{\\\"commit\\\": \\\"$(git ls-remote ${var.autoscaler_repo.url} ${var.autoscaler_repo.branch} | cut -f1)\\\"}\""
  ]
}

resource "terraform_data" "build_cloud_function" {
  triggers_replace = [
    var.autoscaler_repo.url,
    var.autoscaler_repo.branch,
    data.external.repo_commit.result.commit,
    filemd5("${path.module}/scripts/build_cloud_function.sh")
  ]

  provisioner "local-exec" {
    command = "sh ${path.module}/scripts/build_cloud_function.sh"
    environment = {
      REPO_URL    = var.autoscaler_repo.url
      REPO_BRANCH = var.autoscaler_repo.branch
      BUILD_DIR   = local.function_build_dir
    }
  }
}

# Upload built zip to GCS
resource "google_storage_bucket_object" "function_zip" {
  name   = "function-${data.external.repo_commit.result.commit}.zip"
  bucket = google_storage_bucket.function_source.name
  source = local.function_zip_path

  depends_on = [terraform_data.build_cloud_function]
}
