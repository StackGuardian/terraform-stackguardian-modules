data "aws_caller_identity" "current" {}

resource "random_string" "connector_external_id" {
  length  = 24
  special = false
}

# This IAM role is used by the StackGuardian platform/runner to access the S3 bucket.
resource "aws_iam_role" "storage_backend" {
  name = "${var.name_prefix}-private-runner-s3-role"

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
            "sts:ExternalId" = "${var.sg_org_name}:${random_string.connector_external_id.result}"
          }
        }
      }
    ]
  })
}

# This policy allows the StackGuardian platform/runner to access the S3 bucket.
resource "aws_iam_policy" "storage_backend_access" {
  name        = "${var.name_prefix}-runner-s3-policy"
  description = "Policy for access to the Storage Backend (S3 Bucket: ${aws_s3_bucket.this.bucket})"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
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
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "runner_s3" {
  role       = aws_iam_role.storage_backend.name
  policy_arn = aws_iam_policy.storage_backend_access.arn
}
