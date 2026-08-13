output "access_key_id" {
  description = "Generated IAM access key ID."
  value       = aws_iam_access_key.my_access_key.id
}

output "secret_access_key" {
  description = "Generated IAM secret access key. It is retained in Terraform state."
  value       = aws_iam_access_key.my_access_key.secret
  sensitive   = true
}
