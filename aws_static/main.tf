resource "aws_iam_user" "new-user" {
  name = var.iam_user # Change the user name as needed
}

resource "aws_iam_access_key" "my_access_key" {
  user = aws_iam_user.new-user.name
}

output "access_key_id" {
  description = "Generated IAM access key ID."
  value       = aws_iam_access_key.my_access_key.id
}

output "secret_access_key" {
  description = "Generated IAM secret access key. It is retained in Terraform state."
  value       = aws_iam_access_key.my_access_key.secret
  sensitive   = true # This will hide the secret in Terraform outputs
}
