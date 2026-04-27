# IAM Role and Policy for Storage Backend Access (AWS only)

resource "random_string" "connector_external_id" {
  count = local.is_aws ? 1 : 0

  length  = 24
  special = false
}

# This IAM role is used by the StackGuardian platform and runners to access the S3 bucket
resource "aws_iam_role" "storage_backend" {
  count = local.is_aws ? 1 : 0

  name = "${local.effective_prefix}-private-runner-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::163602625436:root",
            "arn:aws:iam::476299211833:root",
            "arn:aws:iam::${data.aws_caller_identity.current[0].account_id}:root"
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
  count = local.is_aws ? 1 : 0

  name        = "${local.effective_prefix}-runner-s3-policy"
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
  count = local.is_aws ? 1 : 0

  role       = aws_iam_role.storage_backend[0].name
  policy_arn = aws_iam_policy.storage_backend_access[0].arn
}

# State migration: moved blocks for backward compatibility
moved {
  from = random_string.connector_external_id
  to   = random_string.connector_external_id[0]
}

moved {
  from = aws_iam_role.storage_backend
  to   = aws_iam_role.storage_backend[0]
}

moved {
  from = aws_iam_policy.storage_backend_access
  to   = aws_iam_policy.storage_backend_access[0]
}

moved {
  from = aws_iam_role_policy_attachment.storage_backend
  to   = aws_iam_role_policy_attachment.storage_backend[0]
}
