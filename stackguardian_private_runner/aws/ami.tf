locals {
  ami_owners = {
    amazon = "amazon"
    ubuntu = "099720109477" # Canonical
    rhel   = "309956199498" # Red Hat
  }

  ami_name_patterns = {
    amazon = "amzn2-ami-hvm-*-x86_64-gp2"
    ubuntu = "ubuntu/images/hvm-ssd/ubuntu-*${var.os_version}-amd64-server-*"
    rhel   = "RHEL-${var.os_version}*"
  }

  ssh_usernames = {
    amazon = "ec2-user"
    ubuntu = "ubuntu"
    rhel   = "ec2-user"
  }
}

# Fetch the latest AMI based on the OS family and version
data "aws_ami" "this" {
  most_recent = true
  owners      = [local.ami_owners[var.os_family]]

  filter {
    name   = "name"
    values = [local.ami_name_patterns[var.os_family]]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Build custom AMI using Packer
resource "null_resource" "build_custom_ami" {
  count = var.build_custom_ami ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      packer init ./packer/ami.json.pkr.hcl
      packer build \
        -var "os_family=${var.os_family}" \
        -var "os_version=${var.os_version}" \
        -var "ssh_username=${local.ssh_usernames[var.os_family]}" \
        -var "base_ami=${data.aws_ami.this.id}" \
        -var "region=${var.aws_region}" \
        -var "vpc_id="${var.vpc_id} \
        -var "subnet_id="${var.public_subnet_id} \
        -machine-readable \
        ./packer/ami.json.pkr.hcl | tee packer_output.txt
    EOT
  }
}

# Parse the AMI ID from the Packer output
data "external" "packer_ami_id" {
  count = var.build_custom_ami ? 1 : 0

  program = [
    "bash",
    "-c",
    "grep 'artifact,0,id' packer_output.txt | tail -1 | cut -d, -f6 | cut -d: -f2 | xargs -I{} echo '{\"ami_id\": \"{}\"}'"
  ]

  depends_on = [null_resource.build_custom_ami]
}

locals {
  runner_ami_id = var.build_custom_ami ? data.external.packer_ami_id[0].result["ami_id"] : data.aws_ami.this.id
}
