output "iam_role_arn" {
  description = "ARN of the IAM role trusted by StackGuardian."
  value       = aws_iam_role.sg_role.arn
}
