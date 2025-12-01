# StackGuardian Runner Group (only created when mode = "create")

resource "stackguardian_runner_group" "this" {
  count = var.mode == "create" ? 1 : 0

  resource_name = local.runner_group_name
  description   = "Private Runner Group for AWS S3 storage backend"

  max_number_of_runners = var.max_runners

  storage_backend_config = {
    type           = "aws_s3"
    aws_region     = var.aws_region
    s3_bucket_name = local.s3_bucket_name
    auth = {
      integration_id = "/integrations/${stackguardian_connector.this[0].resource_name}"
    }
  }

  tags = concat(var.runner_group_tags, [var.override_names.global_prefix])
}
