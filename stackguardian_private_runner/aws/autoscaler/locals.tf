# Extract SG org name from environment if not provided
data "external" "env" {
  program = [
    "sh",
    "-c",
    "echo '{\"sg_org_name\": \"'$${SG_ORG_ID##*/}'\"}'"
  ]
}

# Account id used to build the ARNs referenced by the Lambda IAM policy
# (the region comes from var.aws_region, which also configures the provider)
data "aws_caller_identity" "current" {}

locals {
  # StackGuardian configuration - use provided values or extract from environment
  # Use nonsensitive() for non-secret fields to prevent sensitivity propagation
  sg_org_name = (
    nonsensitive(var.stackguardian.org_name) != ""
    ? nonsensitive(var.stackguardian.org_name)
    : data.external.env.result.sg_org_name
  )
  sg_api_uri = nonsensitive(var.stackguardian.api_uri)

  # Effective prefix for resource naming (optionally includes org name)
  effective_prefix = (
    var.override_names.include_org_in_prefix && local.sg_org_name != ""
    ? "${var.override_names.global_prefix}_${local.sg_org_name}"
    : var.override_names.global_prefix
  )

  # Common tags applied to every taggable resource, plus user supplied extras
  common_tags = merge(
    {
      purpose = "stackguardian-private-runner"
      prefix  = var.override_names.global_prefix
    },
    var.tags
  )

  # Lambda build directory and zip path
  lambda_build_dir = "${path.module}/.lambda_build"
  lambda_zip_path  = "${local.lambda_build_dir}/lambda.zip"

  # Lambda function name
  lambda_function_name = "${local.effective_prefix}-autoscale-private-runner"

  # CloudWatch log group name
  log_group_name = "/aws/lambda/${local.lambda_function_name}"

  # ARN of the Auto Scaling Group the autoscaler is allowed to scale.
  # ASG ARNs embed a service generated UUID that is not known before the group
  # exists, so the UUID segment is wildcarded and the group name is pinned.
  asg_arn = "arn:aws:autoscaling:${var.aws_region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.asg_name}"
}
