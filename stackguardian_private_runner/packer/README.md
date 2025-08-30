# StackGuardian Private Runner - Packer AMI Builder

Build a custom AMI for StackGuardian Private Runner with pre-installed dependencies and optimized configuration.

## What This Template Creates

- **Custom AMI** with StackGuardian Private Runner dependencies pre-installed
- **Multi-OS Support** for Amazon Linux 2, Ubuntu, and RHEL
- **Pre-installed Tools**: Docker, Terraform, OpenTofu, cron, jq, and StackGuardian runner components
- **Optimized Configuration** for faster runner startup and reduced job execution time

## Prerequisites

1. **AWS Permissions** - Your AWS account needs sufficient permissions (see `packer_permissions.json`)
2. **Network Infrastructure** - Existing VPC with internet gateway and public subnet
3. **Packer Installation** - HashiCorp Packer installed locally or in CI/CD environment

## Template Parameters

### Required Configuration

**AWS Configuration**
- `aws_region` - AWS region where the AMI will be built

**Network Configuration** (object)
- `network.vpc_id` - Existing VPC ID (must have internet access)
- `network.public_subnet_id` - Public subnet for the build instance

### Optional Configuration

**Build Instance Settings**
- `instance_type` - EC2 instance type for build (default: t3.medium)

**AMI Cleanup Configuration**
- `cleanup_amis_on_destroy` - Automatically deregister AMIs on terraform destroy (default: true)

**Operating System Configuration** (object)
- `os.family` - Base OS: amazon, ubuntu, or rhel (default: amazon)
- `os.version` - OS version (e.g., 22.04 for Ubuntu, 9.4 for RHEL)
- `os.update_os_before_install` - Update packages before install (default: true)
- `os.ssh_username` - SSH username (auto-detected if not specified)
- `os.user_script` - Custom shell script for additional setup

**Packer Configuration** (object)
- `packer_config.version` - Packer version for builds (default: 1.14.1)

**Terraform Configuration** (object)
- `terraform.primary_version` - Primary Terraform version (default: "")
- `terraform.additional_versions` - Additional Terraform versions (default: [])

**OpenTofu Configuration** (object)
- `opentofu.primary_version` - Primary OpenTofu version (default: "")
- `opentofu.additional_versions` - Additional OpenTofu versions (default: [])

## Configuration Guide

This template creates a customized AMI through the StackGuardian platform interface. Configure the parameters below to match your requirements:

### Basic Setup
- Select your target AWS region
- Provide VPC and subnet details for the build process
- Choose your preferred operating system (Amazon Linux 2, Ubuntu, or RHEL)

### Advanced Configuration
- **Custom Scripts**: Add shell commands to install additional software or configure settings
- **Tool Versions**: Specify which Terraform and OpenTofu versions to pre-install  
- **AMI Management**: Choose whether to automatically clean up AMIs when the template is destroyed

## Outputs

- `ami_id` - The ID of the created AMI
- `ami_info` - Comprehensive AMI information including region, OS details, and timestamp
- `cleanup_commands` - Ready-to-use AWS CLI commands for manual AMI cleanup

## AMI Cleanup and Management

### Automatic Cleanup (Default)

By default, `cleanup_amis_on_destroy = true` enables automatic cleanup:

```bash
terraform destroy
# Automatically deregisters AMIs and deletes snapshots
```

### Manual Cleanup

To preserve AMIs and handle cleanup manually:

```hcl
cleanup_amis_on_destroy = false
```

```bash
terraform destroy
# Creates ami_cleanup_info.txt with cleanup instructions

# Use the provided cleanup script
./scripts/cleanup_amis.sh

# Or use AWS CLI commands from the output
terraform output cleanup_commands
```

### Cost Considerations

- AMI storage costs ~$0.05/GB-month
- Snapshots cost ~$0.05/GB-month  
- Set up billing alerts for AMI storage costs
- Clean up unused AMIs regularly

See `TERRAFORM_DESTROY_GUIDE.md` for detailed cleanup procedures.

## Operating System Support

### Amazon Linux 2 (Recommended)
- Best AWS integration, optimized for AWS services
- SSH User: ec2-user, Package Manager: yum

### Ubuntu LTS
- Large community, extensive package repository
- Versions: 20.04, 22.04
- SSH User: ubuntu, Package Manager: apt

### Red Hat Enterprise Linux (RHEL)
- Enterprise support, security-focused, stable
- Versions: 8.8, 9.6
- SSH User: ec2-user, Package Manager: yum

## Pre-installed Components

The built AMI includes:

### Core Dependencies
- **Docker** - Container runtime for job execution
- **cron** - Job scheduling
- **jq** - JSON processing
- **curl/wget** - HTTP clients
- **git** - Version control
- **unzip** - Archive extraction

### Infrastructure as Code Tools
- **Terraform** - Primary version + additional versions if specified
- **OpenTofu** - Primary version + additional versions if specified

### StackGuardian Components
- **sg-runner** - StackGuardian runner binary
- **main.sh** - Runner startup script
- **Configuration templates** - Pre-configured for optimal performance

## Next Steps

After the AMI is successfully created, use the generated AMI ID with the StackGuardian Private Runner AWS deployment template to launch your private runner instances with the pre-configured environment.

## Template Structure

This StackGuardian template includes:
- **Terraform Configuration**: Infrastructure as Code for AMI creation
- **Packer Templates**: AMI building specifications for multiple OS families
- **Provisioning Scripts**: Automated installation of dependencies and StackGuardian components
- **Cleanup Automation**: Optional AMI lifecycle management
- **Validation Schemas**: Input validation for the StackGuardian platform

For detailed cleanup procedures, refer to the included `TERRAFORM_DESTROY_GUIDE.md`.