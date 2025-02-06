# Step 1: Create an OpenID Connect provider in AWS IAM
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url                     = "https://api.app.stackguardian.io"  # OIDC provider URL
  client_id_list          = [ "https://api.app.stackguardian.io" ]            # OIDC client ID or the Audience id
  thumbprint_list         = []
}

# Step 2: Create an IAM role that can be assumed by users authenticated through the OIDC provider
resource "aws_iam_role" "oidc_role" {
  name               = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
		{
			"Effect": "Allow",
			"Principal": {
				"Federated": "arn:aws:iam::${var.account_number}:oidc-provider/api.app.stackguardian.io"
			},
			"Action": "sts:AssumeRoleWithWebIdentity",
			"Condition": {
				"StringEquals": {
					"api.app.stackguardian.io:aud" = "https://api.app.stackguardian.io"
				},
				"StringLike": {
            "api.app.stackguardian.io:sub" = "/orgs/${var.org_name}"
        }
			}
		}
    ]
  })
}

resource "aws_iam_policy_attachment" "sg_role_policy" {
  name       = "${var.role_name}-policy"
  policy_arn = var.aws_policy
  roles      = [aws_iam_role.oidc_role.name]
}
