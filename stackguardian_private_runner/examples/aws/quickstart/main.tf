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

  override_names = var.override_names

  max_runners                   = var.max_runners
  create_storage_backend        = true
  force_destroy_storage_backend = var.force_destroy_storage_backend
}

# -------------------------------------------------------
# Module 2: Packer AMI Builder
#   Builds AMI with sg-runner, Docker, Terraform, etc.
# -------------------------------------------------------
module "packer" {
  source = "../../../aws/packer"

  aws_region    = var.aws_region
  instance_type = var.packer_instance_type

  network = {
    vpc_id           = var.vpc_id
    public_subnet_id = var.public_subnet_id
  }

  os            = var.os
  packer_config = var.packer_config
  terraform     = var.terraform
  opentofu      = var.opentofu
  sg_runner     = var.sg_runner
}

# -------------------------------------------------------
# Module 3: Single Runner EC2 Instance
#   Deploys the private runner using the AMI from Packer
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

  network = {
    vpc_id                          = var.vpc_id
    public_subnet_id                = var.public_subnet_id
    associate_public_ip             = true
    vpc_endpoint_security_group_ids = var.vpc_endpoint_security_group_ids
  }

  volume                 = var.volume
  firewall               = var.firewall
  runner_startup_timeout = var.runner_startup_timeout
}
