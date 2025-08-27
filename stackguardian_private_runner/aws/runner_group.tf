locals {
  runner_group_name = (
    var.override_names.runner_group_name != ""
    ? var.override_names.runner_group_name
    : "${var.override_names.global_prefix}-runner-group-${data.aws_caller_identity.current.account_id}"
  )
}

# This creates the Runner Group on StackGuardian platform
resource "stackguardian_runner_group" "this" {
  resource_name = local.runner_group_name
  description   = "Private Runner Group for AWS S3 storage backend"

  max_number_of_runners = var.scaling.scale_out_threshold

  storage_backend_config = {
    type           = "aws_s3"
    aws_region     = var.aws_region
    s3_bucket_name = aws_s3_bucket.this.bucket
    auth = {
      integration_id = "/integrations/${stackguardian_connector.this.resource_name}"
    }
  }

  tags = ["private-runner", var.override_names.global_prefix]
}
