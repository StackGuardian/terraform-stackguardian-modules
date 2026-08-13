output "oidc_provider_arn" {
  description = "ARN of the AWS IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.oidc_provider.arn
}

output "oidc_role_arn" {
  description = "ARN of the AWS IAM role trusted by the OIDC provider."
  value       = aws_iam_role.oidc_role.arn
}
