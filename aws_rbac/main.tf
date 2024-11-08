locals {
  orgname = "var.orgname"
}
resource "aws_iam_role" "sg-test-role" {
  name               = var.name
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
            "sts:ExternalId" = "var.orgname:abc12345"  # Replace with your external ID
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "readonly_access" {
  name       = var.policy_name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  roles      = [aws_iam_role.sg-test-role-clara-001.name]
}
