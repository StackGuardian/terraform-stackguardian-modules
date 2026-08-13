resource "aws_iam_role" "sg_role" {
  name        = var.iam_role_name
  description = "StackGuardianIntegrationRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [for account_id in var.trusted_account_ids : "arn:aws:iam::${account_id}:root"]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.role_external_id # Replace with your external ID
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sg_role_policy" {
  role       = aws_iam_role.sg_role.name
  policy_arn = var.policy_arn
}
