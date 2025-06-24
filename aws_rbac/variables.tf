variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region"
}

variable "aws_role_name" {
  type        = string
  description = "Name of the Role within AWS"
}

variable "role_external_id" {
  type = string
  # Example 'my-stackguardian-org:abc12345'
  description = "ExternalID for the Role in AWS - needs to start with the StackGuardian Organisation name."
}

variable "aws_policy" {
  type        = string
  description = "ARN of the AWS Policy to be applied"
  default     = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
