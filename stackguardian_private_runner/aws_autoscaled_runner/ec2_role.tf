# EC2 Instance Role (only created when create_asg = true)
resource "aws_iam_role" "runner" {
  count = var.create_asg ? 1 : 0

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

# Policy to allow EC2 runner to assume the storage backend S3 role
resource "aws_iam_policy" "ec2_runner_assume_s3_role" {
  count = var.create_asg ? 1 : 0

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
          var.storage_backend_role_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_runner_assume_s3_role" {
  count = var.create_asg ? 1 : 0

  role       = aws_iam_role.runner[0].name
  policy_arn = aws_iam_policy.ec2_runner_assume_s3_role[0].arn
}

# Attach SSM policy for Session Manager access
resource "aws_iam_role_policy_attachment" "ec2_runner_ssm" {
  count = var.create_asg ? 1 : 0

  role       = aws_iam_role.runner[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "this" {
  count = var.create_asg ? 1 : 0

  name = "${var.override_names.global_prefix}-runner-instance-profile"
  role = aws_iam_role.runner[0].name
}
