# EC2 Instance Role
resource "aws_iam_role" "runner" {
  name = "${var.override_names.global_prefix}-ec2-private-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy to allow EC2 runner to access S3 bucket
resource "aws_iam_policy" "ec2_runner_assume_s3_role" {
  name        = "${var.override_names.global_prefix}-ec2-runner-assume-s3-role-policy"
  description = "Allow EC2 runner to assume the S3 bucket role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          aws_iam_role.storage_backend.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_runner_assume_s3_role" {
  role       = aws_iam_role.runner.name
  policy_arn = aws_iam_policy.ec2_runner_assume_s3_role.arn
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "this" {
  name = "${var.override_names.global_prefix}-runner-instance-profile"
  role = aws_iam_role.runner.name
}
