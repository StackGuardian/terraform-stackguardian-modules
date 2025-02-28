variable "aws_region" {
  type = string
  default = "eu-central-1"
  description = "AWS region"
}

variable "iam_user" {
  type = string
  default = "example"
  description = "name of the iam user created"
}