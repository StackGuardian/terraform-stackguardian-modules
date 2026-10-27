# S3 Bucket for Storage Backend (created when create_storage_backend = true)

resource "random_string" "storage_backend_prefix" {
  count = var.create_storage_backend ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  count = var.create_storage_backend ? 1 : 0

  bucket        = "${random_string.storage_backend_prefix[0].result}-private-runner-storage-backend"
  force_destroy = var.force_destroy_storage_backend
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create_storage_backend ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "this" {
  count = var.create_storage_backend ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = concat(
      [local.sg_app_uri],
      var.storage_backend_cors_extra_origins,
    )
    expose_headers = []
  }
}

# Object versioning (opt-in via storage_backend_versioning). Destroying this
# resource suspends versioning on the bucket, which is all S3 allows once it has
# been enabled.
resource "aws_s3_bucket_versioning" "this" {
  count = var.create_storage_backend && var.storage_backend_versioning.enabled ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Expire versions noncurrent_retention_days after they are replaced, then drop
# the delete markers left with no versions behind them. Skipped when retention
# is 0 (keep forever).
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = (
    var.create_storage_backend
    && var.storage_backend_versioning.enabled
    && var.storage_backend_versioning.noncurrent_retention_days > 0
  ) ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.storage_backend_versioning.noncurrent_retention_days
    }

    expiration {
      expired_object_delete_marker = true
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# Data source for existing S3 bucket (when using an existing bucket)
data "aws_s3_bucket" "existing" {
  count = var.create_storage_backend ? 0 : 1

  bucket = var.existing_s3_bucket_name
}
