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
- `vpc_id` - Existing VPC ID (must have internet access)
- `public_subnet_id` - Public subnet for the build instance

### Optional Configuration

**Build Instance Settings**
- `instance_type` - EC2 instance type for build (default: t3.medium)

**Operating System**
- `os_family` - Base OS: amazon, ubuntu, or rhel (default: amazon)
- `os_version` - OS version (e.g., 22.04 for Ubuntu, 9.6 for RHEL)
- `update_os_before_install` - Update packages before install (default: false)
- `ssh_username` - SSH username (auto-detected if not specified)

**Tool Versions**
- `packer_version` - Packer version for builds (default: 1.14.1)
- `terraform_version` - Primary Terraform version (default: 1.5.7)
- `terraform_versions` - Additional Terraform versions (default: [])
- `opentofu_version` - Primary OpenTofu version (default: 1.10.5)
- `opentofu_versions` - Additional OpenTofu versions (default: [])

**Customization**
- `user_script` - Custom shell script for additional setup

## Usage Examples

### Basic AMI Build

```hcl
module "packer_ami" {
  source = "./packer"

  aws_region       = "eu-central-1"
  vpc_id          = "vpc-12345678"
  public_subnet_id = "subnet-87654321"
}
```

### Ubuntu AMI with Multiple Terraform Versions

```hcl
module "packer_ami" {
  source = "./packer"

  aws_region       = "us-west-2"
  vpc_id          = "vpc-12345678"
  public_subnet_id = "subnet-87654321"
  
  os_family  = "ubuntu"
  os_version = "22.04"
  
  terraform_version  = "1.6.0"
  terraform_versions = ["1.4.6", "1.5.7", "1.7.0"]
  
  update_os_before_install = true
}
```

## Outputs

- `ami_id` - The ID of the created AMI

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

## Integration with AWS Module

Once the AMI is built, use it with the main AWS deployment:

```hcl
module "private_runner" {
  source = "../aws"
  
  ami_id = module.packer_ami.ami_id
  
  aws_region = "eu-central-1"
  stackguardian = {
    api_key  = "sgu_your_api_key"
    org_name = "your-org"
  }
  network = {
    vpc_id            = "vpc-12345678"
    public_subnet_id  = "subnet-87654321"
    associate_public_ip = true
  }
}
```