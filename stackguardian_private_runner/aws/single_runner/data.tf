# Data sources for fetching runner group configuration

# Fetch runner group details including S3 bucket name
data "stackguardian_runner_group" "this" {
  resource_name = var.runner_group_name
}

# Fetch runner group token for registration
data "stackguardian_runner_group_token" "this" {
  runner_group_id = var.runner_group_name
}

# Fetch S3 bucket details
data "aws_s3_bucket" "this" {
  bucket = data.stackguardian_runner_group.this.storage_backend_config.s3_bucket_name
}
