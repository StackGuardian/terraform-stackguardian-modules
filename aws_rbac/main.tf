resource "aws_iam_role" "sg-test-role" {
  name               = var.role_name
  description = "StackGuardianIntegrationRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::476299211833:root",
          "arn:aws:iam::163602625436:root"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.role_external_id  # Replace with your external ID
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "sg_role_policy" {
  name       = "${var.role_name}-policy"
  policy_arn = var.aws_policy
  roles      = [aws_iam_role.sg-test-role.name]
}
