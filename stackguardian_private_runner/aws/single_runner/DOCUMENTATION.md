# StackGuardian Private Runner - AWS Single Runner Template

Deploy a standalone StackGuardian Private Runner on AWS using the StackGuardian platform.

## Overview

This template creates a single EC2 instance configured as a StackGuardian Private Runner. The runner automatically registers with your organization and executes workflows in your private AWS environment, giving you full control over where your infrastructure code runs.

### What This Template Creates

- **EC2 Instance** running the StackGuardian runner with your custom AMI
- **IAM Role** with permissions for S3 storage backend access and SSM Session Manager
- **Security Group** with configurable firewall rules
- **NAT Gateway** (optional) for private subnet internet connectivity
- **VPC Endpoint Rules** (optional) for private AWS service access

## Prerequisites

1. **StackGuardian API Key** - Generate from your organization settings (starts with `sgu_` or `sgo_`)
2. **Custom AMI** - Build using the Packer template with required dependencies
3. **Runner Group** - Create using the Runner Group template to get the runner group name and storage backend role ARN
4. **AWS VPC** - Existing VPC with at least one subnet

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| API Key | Your StackGuardian API key | `string` |
| AMI ID | The AMI with pre-installed dependencies (docker, cron, jq, sg-runner) | `string` |
| Runner Group Name | Name of the runner group from the Runner Group template | `string` |
| Storage Backend Role ARN | IAM role ARN for S3 storage access from the Runner Group template | `string` |
| VPC ID | Existing VPC for deployment | `string` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| API Region | StackGuardian API endpoint (EU1, US1, or DASH) | EU1 - Europe |
| Organization Name | Your organization name (auto-detected if not provided) | - |
| AWS Region | Target AWS region for deployment | `eu-central-1` |
| Instance Type | EC2 instance type (min 4 vCPU, 8GB RAM recommended) | `t3.xlarge` |
| Global Prefix | Prefix for naming all AWS resources | `SG_RUNNER` |
| Include Organization in Prefix | Append organization name to resource prefix | `false` |
| Private Subnet ID | Private subnet for secure deployments | - |
| Public Subnet ID | Public subnet (required for NAT Gateway) | - |
| Associate Public IP | Assign a public IP to the instance | `false` |
| Create Network Infrastructure | Create NAT Gateway and route tables | `false` |
| Proxy URL | HTTP proxy for private network deployments | - |
| Additional Security Groups | Extra security groups to attach | `[]` |
| VPC Endpoint Security Groups | Security groups of VPC endpoints (STS, SSM, ECR). Adds inbound 443 rule to allow runner access. | `[]` |
| Volume Type | EBS volume type (gp2, gp3, io1, io2) | `gp3` |
| Volume Size (GB) | Storage size in GB (minimum 8GB) | `100` |
| Delete on Termination | Delete volume when instance terminates | `false` |
| SSH Key Name | Existing AWS key pair name for SSH access | - |
| SSH Public Key | Custom SSH public key content | - |
| SSH Access Rules | CIDR blocks allowed for SSH access (format: x.x.x.x/0-32) | `{}` |
| Additional Ingress Rules | Custom firewall rules with port, protocol, and CIDR blocks | `{}` |
| Runner Startup Timeout | Seconds to wait for Docker startup | `300` |

## Important Notes

**AMI Requirements**: Your AMI must include Docker, cron, jq, and the sg-runner binary. Use the StackGuardian Packer template to build a compatible AMI.

**Runner Group Dependency**: This template requires outputs from the Runner Group template. Deploy the Runner Group template first to obtain the `runner_group_name` and `storage_backend_role_arn` values.

**Network Connectivity**: The runner needs outbound HTTPS (port 443) access to communicate with StackGuardian. For private subnet deployments:
- Enable NAT Gateway creation, or
- Configure a proxy URL, or
- Use VPC endpoints with `vpc_endpoint_security_group_ids`

**VPC Endpoints**: For fully private deployments without internet access, create VPC endpoints for AWS services (STS, SSM, ECR, S3) and provide their security group IDs. The template automatically adds inbound rules to allow the runner to access these endpoints.

**Subnet Priority**: When both private and public subnets are provided, the instance is deployed to the private subnet.

**SSH Access**: SSH access is disabled by default. To enable, provide an SSH key and configure access rules with allowed CIDR blocks.

## Outputs

| Output | Description |
|--------|-------------|
| Instance ID | EC2 instance identifier for management |
| Private IP | Internal IP address of the runner |
| Public IP | External IP address (if assigned) |
| Security Group ID | ID of the created security group |
| IAM Role Name | Name of the IAM role attached to the instance |
| IAM Role ARN | Role ARN for reference in other configurations |
| IAM Instance Profile Name | Name of the instance profile |
| NAT Gateway ID | NAT Gateway identifier (when created) |
| NAT Gateway Public IP | NAT Gateway external IP (when created) |

## Security Features

- IMDSv2 required for instance metadata access
- Security group allows only outbound traffic by default
- SSH access requires explicit configuration with CIDR validation
- API keys stored as sensitive values
- SSM Session Manager enabled for secure access without SSH
- Private subnet deployment supported with NAT Gateway, proxy, or VPC endpoints
- Automatic VPC endpoint security group rules for private connectivity

## Usage

After deployment:

1. The runner automatically registers with your StackGuardian organization
2. Navigate to **Orchestrator > Runner Groups** to verify registration
3. Configure your workflows to use the runner group name
4. Monitor runner health and job execution in the StackGuardian platform

For auto-scaling capabilities, consider using the Autoscaling Group Runner template instead.
