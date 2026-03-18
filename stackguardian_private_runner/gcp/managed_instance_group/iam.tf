# GCP Service Account for runner instances
resource "google_service_account" "runner" {
  account_id   = "${local.effective_prefix_lower}-runner-sa"
  display_name = "${local.effective_prefix} Private Runner Service Account"
  project      = var.gcp_project_id
}

# Grant logging permissions
resource "google_project_iam_member" "runner_log_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

# Grant monitoring permissions
resource "google_project_iam_member" "runner_metric_writer" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.runner.email}"
}

# --------------------------------------------------------------------------
# AWS side: Cross-cloud S3 access via Workload Identity Federation (OIDC)
# --------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# OIDC provider for GCP identity tokens
resource "aws_iam_openid_connect_provider" "gcp" {
  url             = "https://accounts.google.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["08745487e891c19e3078c1f2a07e452950ef36f6"]
}

# IAM role trusted by the GCP service account via OIDC federation
resource "aws_iam_role" "gcp_s3_access" {
  name = "${local.effective_prefix}-gcp-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/accounts.google.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "accounts.google.com:sub" = google_service_account.runner.unique_id
          }
        }
      }
    ]
  })
}

# S3 access policy (same permissions as runner_group/storage_backend_role.tf)
resource "aws_iam_policy" "gcp_s3_access" {
  name        = "${local.effective_prefix}-gcp-s3-access-policy"
  description = "Policy for GCP runner access to the Storage Backend S3 Bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:DeleteObjectTagging",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:PutObjectVersionTagging",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObjectTagging",
          "s3:DeleteObjectVersionTagging",
          "s3:DeleteObject"
        ]
        Resource = [
          local.s3_bucket_arn,
          "${local.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gcp_s3_access" {
  role       = aws_iam_role.gcp_s3_access.name
  policy_arn = aws_iam_policy.gcp_s3_access.arn
}
