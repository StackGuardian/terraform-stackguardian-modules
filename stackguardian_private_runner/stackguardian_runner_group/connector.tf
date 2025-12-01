# StackGuardian Connector (only created when mode = "create")

resource "stackguardian_connector" "this" {
  count = var.mode == "create" ? 1 : 0

  resource_name = local.connector_name
  description   = "AWS connector for accessing Private Runner storage backend (S3 Bucket: ${local.s3_bucket_name})."

  settings = {
    kind = "AWS_RBAC"

    config = [{
      role_arn         = aws_iam_role.storage_backend[0].arn
      external_id      = "${local.sg_org_name}:${random_string.connector_external_id[0].result}"
      duration_seconds = "3600"
    }]
  }

  tags = concat(var.runner_group_tags, [var.override_names.global_prefix])
}
