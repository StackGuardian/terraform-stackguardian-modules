variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-\\d$", var.aws_region))
    error_message = "aws_region must be a valid AWS region."
  }
}

variable "iam_user" {
  type        = string
  default     = "example"
  description = "Name of the IAM user created. Its generated static secret is retained in Terraform state."
}
