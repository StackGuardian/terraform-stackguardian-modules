# IAM Role and Policy for Storage Backend Access
# Always created when mode = "create" (needed for connector and runner access)

resource "random_string" "connector_external_id" {
  count = var.mode == "create" ? 1 : 0

  length  = 24
  special = false
}

# This IAM role is used by the StackGuardian platform and runners to access the S3 bucket
resource "aws_iam_role" "storage_backend" {
  count = var.mode == "create" ? 1 : 0

  name = "${var.override_names.global_prefix}-private-runner-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::163602625436:root",
            "arn:aws:iam::476299211833:root",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "${local.sg_org_name}:${random_string.connector_external_id[0].result}"
          }
        }
      }
    ]
  })
}

# This policy allows the StackGuardian platform/runner to access the S3 bucket
resource "aws_iam_policy" "storage_backend_access" {
  count = var.mode == "create" ? 1 : 0

  name        = "${var.override_names.global_prefix}-runner-s3-policy"
  description = "Policy for access to the Storage Backend S3 Bucket"

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

resource "aws_iam_role_policy_attachment" "storage_backend" {
  count = var.mode == "create" ? 1 : 0

  role       = aws_iam_role.storage_backend[0].name
  policy_arn = aws_iam_policy.storage_backend_access[0].arn
}
