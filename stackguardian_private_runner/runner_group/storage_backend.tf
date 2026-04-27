# S3 Bucket for Storage Backend (AWS only, created when create_storage_backend = true)

resource "random_string" "storage_backend_prefix" {
  count = local.is_aws && var.create_storage_backend ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  count = local.is_aws && var.create_storage_backend ? 1 : 0

  bucket        = "${random_string.storage_backend_prefix[0].result}-private-runner-storage-backend"
  force_destroy = var.force_destroy_storage_backend
}

resource "aws_s3_bucket_public_access_block" "this" {
  count = local.is_aws && var.create_storage_backend ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "this" {
  count = local.is_aws && var.create_storage_backend ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = [
      local.sg_app_uri
    ]
    expose_headers = []
  }
}

# Data source for existing S3 bucket (when using existing bucket, AWS only)
data "aws_s3_bucket" "existing" {
  count = local.is_aws && !var.create_storage_backend ? 1 : 0

  bucket = var.existing_s3_bucket_name
}
