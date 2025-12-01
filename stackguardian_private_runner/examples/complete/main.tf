# Complete Example: Full deployment with new runner group and autoscaled runners
# This example creates a new StackGuardian runner group with S3 storage backend
# and deploys an autoscaling EC2 runner infrastructure.

# Step 1: Create StackGuardian Runner Group with all platform resources
module "sg_runner_group" {
  source = "../../stackguardian_runner_group"

  mode                   = "create"
  create_storage_backend = true

  stackguardian = {
    api_key  = var.sg_api_key
    org_name = var.sg_org_name
  }

  aws_region = var.aws_region

  override_names = {
    global_prefix = var.name_prefix
  }

  max_runners = var.max_runners
}

# Step 2: Deploy autoscaled runners
module "aws_autoscaled_runner" {
  source = "../../aws_autoscaled_runner"

  create_asg = true
  ami_id     = var.ami_id

  # From runner group module outputs
  runner_group_name        = module.sg_runner_group.runner_group_name
  runner_group_token       = module.sg_runner_group.runner_group_token
  storage_backend_role_arn = module.sg_runner_group.storage_backend_role_arn
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

  volume = {
    type                  = "gp3"
    size                  = 100
    delete_on_termination = false
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

output "runner_group_url" {
  description = "URL to runner group in StackGuardian console"
  value       = module.sg_runner_group.runner_group_url
}

output "s3_bucket_name" {
  description = "S3 bucket for storage backend"
  value       = module.sg_runner_group.s3_bucket_name
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = module.aws_autoscaled_runner.autoscaling_group_name
}

output "lambda_function_name" {
  description = "Lambda autoscaler function name"
  value       = module.aws_autoscaled_runner.lambda_function_name
}
