output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc_provider.arn
}

output "oidc_role_arn" {
  value = aws_iam_role.oidc_role.arn
}