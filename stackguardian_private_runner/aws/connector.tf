# This creates the AWS Connector on StackGuardian platform
resource "stackguardian_connector" "this" {
  resource_name = "${var.name_prefix}-private-runner-backend"
  description   = "AWS connector for accessing Private Runner storage backend (S3 Bucket: ${aws_s3_bucket.this.bucket})."

  settings = {
    kind = "AWS_RBAC"

    config = [{
      role_arn         = aws_iam_role.storage_backend.arn
      external_id      = "${var.sg_org_name}:${random_string.connector_external_id.result}"
      duration_seconds = "3600"
    }]
  }

  tags = ["private-runner", var.name_prefix]
}
