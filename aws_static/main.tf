resource "aws_iam_user" "new-user" {
  name = var.iam_user  # Change the user name as needed
}

resource "aws_iam_access_key" "my_access_key" {
  user = aws_iam_user.new-user.name
}

output "access_key_id" {
  value = aws_iam_access_key.my_access_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.my_access_key.secret
  sensitive = true  # This will hide the secret in Terraform outputs
}
