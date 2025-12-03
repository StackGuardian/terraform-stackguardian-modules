resource "random_string" "storage_backend_prefix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket        = "${random_string.storage_backend_prefix.result}-private-runner-storage-backend"
  force_destroy = var.force_destroy_storage_backend
}

# Optional: Block public access
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    # allowed_origins = ["https://app.stackguardian.io"]
    allowed_origins = [
      "${replace(data.external.env.result.sg_api_uri, "api.", "")}"
    ]
    expose_headers = []
  }
}
