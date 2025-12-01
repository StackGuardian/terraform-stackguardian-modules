# Standalone EC2 Example: Single EC2 instance runner without autoscaling
# This example creates a runner group and deploys a single standalone EC2 runner.

# Step 1: Create StackGuardian Runner Group
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

  max_runners = 1
}

# Step 2: Deploy standalone EC2 runner
module "aws_runner" {
  source = "../../aws_runner"

  ami_id        = var.ami_id
  instance_type = var.instance_type

  # Runner group name - token and bucket are fetched via data sources
  runner_group_name        = module.sg_runner_group.runner_group_name
  storage_backend_role_arn = module.sg_runner_group.storage_backend_role_arn

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

  volume = {
    type                  = "gp3"
    size                  = 100
    delete_on_termination = false
  }

  firewall = {
    ssh_access_rules = var.ssh_cidr_blocks
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
  description = "Subnet ID for runner instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for runner instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "SG_RUNNER"
}

variable "associate_public_ip" {
  description = "Whether to associate public IP"
  type        = bool
  default     = true
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = map(string)
  default     = {}
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

output "instance_id" {
  description = "EC2 instance ID"
  value       = module.aws_runner.instance_id
}

output "instance_private_ip" {
  description = "EC2 instance private IP"
  value       = module.aws_runner.instance_private_ip
}

output "instance_public_ip" {
  description = "EC2 instance public IP"
  value       = module.aws_runner.instance_public_ip
}
