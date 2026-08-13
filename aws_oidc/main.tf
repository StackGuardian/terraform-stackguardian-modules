# Step 1: Create an OpenID Connect provider in AWS IAM
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url             = var.oidc_issuer_url
  client_id_list  = [var.oidc_audience]
  thumbprint_list = []
}

# Step 2: Create an IAM role that can be assumed by users authenticated through the OIDC provider
resource "aws_iam_role" "oidc_role" {
  name = var.iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.oidc_provider.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "api.app.stackguardian.io:aud" = var.oidc_audience
          },
          "StringLike" : {
            "api.app.stackguardian.io:sub" = "/orgs/${var.stackguardian_org_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sg_role_policy" {
  role       = aws_iam_role.oidc_role.name
  policy_arn = var.policy_arn
}
