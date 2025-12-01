# Existing Runner Group Example: Use an existing runner group with new autoscaled runners
# This example uses an existing StackGuardian runner group and deploys autoscaled runners.

# Step 1: Reference existing StackGuardian Runner Group
module "sg_runner_group" {
  source = "../../stackguardian_runner_group"

  mode                       = "existing"
  existing_runner_group_name = var.existing_runner_group_name

  # When using existing, you can either use the existing S3 bucket from the runner group
  # or specify your own bucket
  create_storage_backend  = false
  existing_s3_bucket_name = var.existing_s3_bucket_name

  stackguardian = {
    api_key  = var.sg_api_key
    org_name = var.sg_org_name
  }

  aws_region = var.aws_region
}

# Step 2: Deploy autoscaled runners with the existing runner group
module "aws_autoscaled_runner" {
  source = "../../aws_autoscaled_runner"

  create_asg = true
  ami_id     = var.ami_id

  # From runner group module outputs (fetched via data sources)
  runner_group_name        = module.sg_runner_group.runner_group_name
  runner_group_token       = module.sg_runner_group.runner_group_token
  storage_backend_role_arn = var.storage_backend_role_arn  # Must provide when using existing
  s3_bucket_name           = module.sg_runner_group.s3_bucket_name

  stackguardian = {
    api_key  = var.sg_api_key
    org_name = module.sg_runner_group.sg_org_name
    api_uri  = module.sg_runner_group.sg_api_uri
  }

  aws_region = var.aws_region

  override_names = {
    global_prefix = var.name_prefix
  }

  network = {
    vpc_id              = var.vpc_id
    subnet_id           = var.subnet_id
    associate_public_ip = var.associate_public_ip
  }

  scaling = {
    min_size         = var.min_runners
    max_size         = var.max_runners
    desired_capacity = var.desired_runners
  }
}

# Variables
variable "sg_api_key" {
  description = "StackGuardian API key"
  type        = string
  sensitive   = true
}

variable "sg_org_name" {
  description = "StackGuardian organization name"
  type        = string
}

variable "existing_runner_group_name" {
  description = "Name of existing StackGuardian runner group"
  type        = string
}

variable "existing_s3_bucket_name" {
  description = "Name of existing S3 bucket for storage backend"
  type        = string
}

variable "storage_backend_role_arn" {
  description = "ARN of existing IAM role for storage backend access"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for runner instances"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for runner instances"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "SG_RUNNER"
}

variable "associate_public_ip" {
  description = "Whether to associate public IP"
  type        = bool
  default     = false
}

variable "min_runners" {
  description = "Minimum number of runners"
  type        = number
  default     = 1
}

variable "max_runners" {
  description = "Maximum number of runners"
  type        = number
  default     = 3
}

variable "desired_runners" {
  description = "Desired number of runners"
  type        = number
  default     = 1
}

# Outputs
output "runner_group_name" {
  description = "StackGuardian runner group name"
  value       = module.sg_runner_group.runner_group_name
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.aws_autoscaled_runner.autoscaling_group_name
}

output "lambda_function_name" {
  description = "Lambda autoscaler function name"
  value       = module.aws_autoscaled_runner.lambda_function_name
}
