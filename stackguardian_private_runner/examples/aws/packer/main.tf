terraform {
  # terraform_data (used by the packer module to record the built AMI ID) needs 1.4+
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    null = {
      source = "hashicorp/null"
    }
    external = {
      source = "hashicorp/external"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

# No provider block here: aws/packer declares its own and configures the region
# from the aws_region it is given.

# -------------------------------------------------------
# Existing Network
#   The build instance runs in a VPC and subnet you already
#   have; this example never creates networking.
# -------------------------------------------------------
data "aws_vpc" "build" {
  id = var.network.vpc_id
}

data "aws_subnet" "build" {
  id = var.network.subnet_id

  # A subnet from another VPC resolves fine on its own and only fails later,
  # when Packer launches the instance. Catch it during plan.
  lifecycle {
    postcondition {
      condition     = self.vpc_id == var.network.vpc_id
      error_message = "network.subnet_id belongs to VPC ${self.vpc_id}, not to network.vpc_id (${var.network.vpc_id})."
    }
  }
}

# -------------------------------------------------------
# Packer AMI Builder
#   Builds the runner AMI: Docker, jq, cron, sg-runner and
#   optionally Terraform/OpenTofu.
# -------------------------------------------------------
module "packer" {
  source = "../../../aws/packer"

  aws_region    = var.aws_region
  instance_type = var.instance_type

  # The module takes exactly one of public_subnet_id / private_subnet_id; which
  # one your subnet is decides how Packer reaches the build instance.
  network = {
    vpc_id            = data.aws_vpc.build.id
    public_subnet_id  = var.network.private_subnet ? "" : data.aws_subnet.build.id
    private_subnet_id = var.network.private_subnet ? data.aws_subnet.build.id : ""
    proxy_url         = var.network.proxy_url
  }

  os              = var.os
  packer_config   = var.packer_config
  ami_name_prefix = var.ami_name_prefix
  terraform       = var.terraform
  opentofu        = var.opentofu
  sg_runner       = var.sg_runner
}
