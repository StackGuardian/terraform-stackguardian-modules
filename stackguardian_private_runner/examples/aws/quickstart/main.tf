terraform {
  required_providers {
    stackguardian = {
      source  = "registry.terraform.io/StackGuardian/stackguardian"
      version = ">= 1.3.3"
    }
    aws = {
      source = "hashicorp/aws"
    }
    external = {
      source = "hashicorp/external"
    }
    random = {
      source = "hashicorp/random"
    }
    null = {
      source = "hashicorp/null"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

# -------------------------------------------------------
# Module 1: StackGuardian Runner Group
#   Creates: runner group, S3 bucket, IAM role, connector
# -------------------------------------------------------
module "runner_group" {
  source = "../../../aws/runner_group"

  stackguardian = var.stackguardian
  aws_region    = var.aws_region

  # The runner group module names only the platform records, so it takes the
  # naming fields and not include_org_in_prefix (which the VM modules still use).
  override_names = {
    global_prefix     = var.override_names.global_prefix
    runner_group_name = var.override_names.runner_group_name
    connector_name    = var.override_names.connector_name
  }

  max_runners                   = var.max_runners
  create_storage_backend        = true
  force_destroy_storage_backend = var.force_destroy_storage_backend
}

# -------------------------------------------------------
# Existing Network
#   This example attaches the runner to a VPC and subnet
#   you already have; it never creates networking.
# -------------------------------------------------------
data "aws_vpc" "runner" {
  id = var.network.vpc_id
}

data "aws_subnet" "runner" {
  id = var.network.subnet_id

  # A subnet from another VPC resolves fine on its own and only fails later,
  # when the instance or the security group is created. Catch it during plan.
  lifecycle {
    postcondition {
      condition     = self.vpc_id == var.network.vpc_id
      error_message = "network.subnet_id belongs to VPC ${self.vpc_id}, not to network.vpc_id (${var.network.vpc_id})."
    }
  }
}

# -------------------------------------------------------
# Module 2: Packer AMI Builder
#   Builds AMI with sg-runner, Docker, Terraform, etc.
#   Passing var.ami_id skips the build: the module then
#   creates nothing and hands that AMI straight back.
#   (The module owns the skip because it declares its own
#   provider, which rules out count on the module call.)
# -------------------------------------------------------
module "packer" {
  source = "../../../aws/packer"

  existing_ami_id = var.ami_id

  aws_region    = var.aws_region
  instance_type = var.packer_instance_type

  network = {
    vpc_id           = data.aws_vpc.runner.id
    public_subnet_id = data.aws_subnet.runner.id
  }

  os              = var.os
  packer_config   = var.packer_config
  ami_name_prefix = var.ami_name_prefix
  terraform       = var.terraform
  opentofu        = var.opentofu
  sg_runner       = var.sg_runner
}

# -------------------------------------------------------
# Module 3: Single Runner EC2 Instance
#   Deploys the private runner using the AMI from Module 2
#   and the runner group config from Module 1
# -------------------------------------------------------
module "single_runner" {
  source = "../../../aws/single_runner"

  ami_id        = module.packer.ami_id
  instance_type = var.runner_instance_type

  runner_group_name        = module.runner_group.runner_group_name
  runner_group_token       = module.runner_group.runner_group_token
  storage_backend_role_arn = module.runner_group.storage_backend_role_arn

  stackguardian = var.stackguardian
  aws_region    = var.aws_region

  override_names = {
    global_prefix         = var.override_names.global_prefix
    include_org_in_prefix = var.override_names.include_org_in_prefix
  }

  # The module can also create NAT gateways and route tables; this example never
  # does, so create_network_infrastructure stays at its default of false.
  network = {
    vpc_id                          = data.aws_vpc.runner.id
    public_subnet_id                = data.aws_subnet.runner.id
    associate_public_ip             = var.network.associate_public_ip
    vpc_endpoint_security_group_ids = var.network.vpc_endpoint_security_group_ids
  }

  volume                 = var.volume
  firewall               = var.firewall
  runner_startup_timeout = var.runner_startup_timeout
}
