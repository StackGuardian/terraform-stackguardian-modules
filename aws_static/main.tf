resource "aws_iam_user" "new-user" {
  name = var.iam_user

  lifecycle {
    precondition {
      condition     = var.allow_static_credentials
      error_message = "Static AWS credentials are deprecated. Set allow_static_credentials = true only when required; prefer aws_rbac or aws_oidc."
    }
  }
}

resource "aws_iam_access_key" "my_access_key" {
  user = aws_iam_user.new-user.name

  lifecycle {
    precondition {
      condition     = var.allow_static_credentials
      error_message = "Static AWS credentials are deprecated. Set allow_static_credentials = true only when required; prefer aws_rbac or aws_oidc."
    }
  }
}

resource "terraform_data" "static_credentials_deprecation" {
  count = var.allow_static_credentials ? 1 : 0
  input = "Static AWS credentials are deprecated; migrate to aws_rbac or aws_oidc."

  provisioner "local-exec" {
    command = "printf '%s\\n' 'WARNING: Static AWS credentials are deprecated; migrate to aws_rbac or aws_oidc.'"
  }
}
