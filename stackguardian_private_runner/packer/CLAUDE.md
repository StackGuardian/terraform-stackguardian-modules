# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Packer-based AMI builder for StackGuardian Private Runner that creates custom AMIs with pre-installed dependencies (Docker, Terraform, OpenTofu, sg-runner, etc.) across multiple operating systems (Amazon Linux 2, Ubuntu, RHEL).

## Common Commands

### Build AMI

```bash
terraform init
terraform plan
terraform apply
```

### Clean Up Resources

```bash
terraform destroy
```

### Manual AMI Cleanup

```bash
# Interactive cleanup
./scripts/cleanup_amis.sh

# Automated cleanup (for destroy operations)
TERRAFORM_DESTROY=true ./scripts/cleanup_amis.sh
```

### Check Build Output

```bash
# View Packer build logs
cat packer_manifest.log

# Get created AMI ID
grep 'artifact,0,id' packer_manifest.log | tail -1 | cut -d, -f6 | cut -d: -f2
```

## Architecture

### Core Components

- **main.tf**: Orchestrates Packer build process via `null_resource` with local-exec provisioner
- **ami.pkr.hcl**: Packer template defining AMI build configuration and provisioning steps
- **variables.tf**: Terraform input variables including OS selection, network config, tool versions
- **locals.tf**: AMI selection mappings for different OS families (Amazon Linux, Ubuntu, RHEL)
- **outputs.tf**: Provides AMI ID, metadata, and cleanup commands

### Scripts

- **scripts/build_ami.sh**: Downloads Packer and executes build with environment variables
- **scripts/setup.sh**: Installs dependencies (Docker, tools, sg-runner) inside AMI
- **scripts/cleanup_amis.sh**: Interactive/automated AMI deregistration and snapshot cleanup

### Build Process Flow

1. Terraform detects base AMI using data sources and local mappings
2. `null_resource.packer_build` triggers `build_ami.sh` with environment variables
3. Script downloads Packer binary and executes `ami.pkr.hcl`
4. Packer provisions EC2 instance and runs `setup.sh` to install dependencies
5. Packer creates AMI snapshot and deregisters build instance
6. `external` data source parses AMI ID from `packer_manifest.log`

### AMI Management

- AMIs include deregistration protection by default (configurable via `packer_config.deregistration_protection`)
- `packer_config.cleanup_amis_on_destroy` variable controls automatic cleanup behavior
- Manual cleanup available via dedicated script for cost management
- AMI naming: `SG-RUNNER-ami-{os_family}{version}-{timestamp}`

### Multi-OS Support

OS-specific configurations handled through:

- **locals.tf**: AMI owner IDs, name patterns, SSH usernames
- **setup.sh**: Package manager detection (apt/yum/dnf) and OS-specific installations
- **variables.tf**: OS family validation and version handling

## Configuration

### Required Variables

- `network.vpc_id`: VPC for AMI build instance
- `network.public_subnet_id` OR `network.private_subnet_id`: Subnet for Packer build (exactly one required)
- `aws_region`: Target region for AMI creation

### Network Configuration Options

#### Public Subnet Build (Default)
```hcl
network = {
  vpc_id           = "vpc-12345678"
  public_subnet_id = "subnet-12345678"
}
```

#### Private Subnet Build
```hcl
network = {
  vpc_id            = "vpc-12345678"
  private_subnet_id = "subnet-87654321"
  proxy_url         = "http://proxy.company.com:8080"  # Optional
}
```

**Private Network Requirements:**
- NAT Gateway or VPC Endpoints for internet access
- Security groups allowing outbound HTTPS (443) and HTTP (80)
- For proxy environments: configure `proxy_url` parameter

### Key Optional Variables

- `os.family`: Operating system (amazon/ubuntu/rhel)
- `os.version`: OS version string
- `terraform.primary_version` / `terraform.additional_versions`: Terraform versions to install
- `opentofu.primary_version` / `opentofu.additional_versions`: OpenTofu versions to install
- `packer_config.cleanup_amis_on_destroy`: Enable automatic AMI cleanup during destroy (bypasses protection except cooldown)
- `packer_config.deregistration_protection`: Configure AMI deregistration protection (enabled/with_cooldown)
- `packer_config.delete_snapshots`: Delete EBS snapshots during AMI cleanup (default: true)

### Packer Configuration Options

#### Deregistration Protection
Control AMI deregistration protection to prevent accidental deletion:

```hcl
packer_config = {
  version = "1.14.1"
  deregistration_protection = {
    enabled = true        # Enable/disable deregistration protection
    with_cooldown = false # Enable/disable cooldown period
  }
  delete_snapshots = true  # Delete EBS snapshots during cleanup
}
```

Defaults: `enabled` is `true`, `with_cooldown` is `false` for flexibility.

#### Automatic Cleanup Behavior
When `packer_config.cleanup_amis_on_destroy = true` (default), automatic cleanup:

```hcl
packer_config = {
  cleanup_amis_on_destroy = true  # Enable automatic cleanup during destroy
  delete_snapshots = false # Preserve snapshots for compliance/backup
}
```

**Automatic Cleanup Behavior:**
- Always attempts to bypass AMI deregistration protection
- Respects cooldown periods (manual cleanup required if cooldown active)
- Provides manual commands when cooldown prevents immediate cleanup
- Only affects the specific AMI created by this Terraform configuration

## Important Notes

- AMIs persist after `terraform destroy` unless `packer_config.cleanup_amis_on_destroy = true`
- **Public builds**: Require VPC with internet gateway and public subnet
- **Private builds**: Require NAT Gateway or VPC Endpoints for external downloads
- Packer binary is downloaded dynamically during build (not pre-installed)
- All tools (Terraform, OpenTofu, jq) are installed from official releases during provisioning
- Private network builds support proxy configuration for corporate environments
- See `TERRAFORM_DESTROY_GUIDE.md` for detailed cleanup procedures and cost considerations

