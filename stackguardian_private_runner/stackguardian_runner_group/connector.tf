# StackGuardian Connector

resource "stackguardian_connector" "this" {
  resource_name = local.connector_name
  description   = "AWS connector for accessing Private Runner storage backend (S3 Bucket: ${local.s3_bucket_name})."

  settings = {
    kind = "AWS_RBAC"

    config = [{
      role_arn         = aws_iam_role.storage_backend.arn
      external_id      = "${local.sg_org_name}:${random_string.connector_external_id.result}"
      duration_seconds = "3600"
    }]
  }

  tags = concat(var.runner_group_tags, [var.override_names.global_prefix])
}
