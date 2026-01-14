# StackGuardian Autoscaled Private Runner - AWS Template

Deploy an auto-scaling fleet of StackGuardian Private Runners on AWS using the StackGuardian platform.

## Overview

This template creates an automatically scaling group of EC2 instances that run StackGuardian Private Runner agents. The fleet size adjusts dynamically based on your job queue, scaling up when jobs are waiting and scaling down during idle periods. This ensures you have the right amount of compute capacity to handle your workloads efficiently.

### What This Template Creates

- **Auto Scaling Group** - A fleet of EC2 instances that automatically adjusts capacity
- **Launch Template** - Configuration for new runner instances
- **Security Group** - Network rules to protect your runner instances
- **IAM Role** - Permissions for runners to access storage and AWS services
- **NAT Gateway** (optional) - Internet connectivity for private subnet deployments

## Prerequisites

- StackGuardian organization API key
- AWS account with appropriate permissions (see aws_permissions.json)
- VPC with at least one subnet
- Custom AMI built using the StackGuardian Packer template
- Runner group created via the StackGuardian Runner Group template

## Template Parameters

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| StackGuardian API Key | Your organization's API key on the StackGuardian Platform | string |
| Runner Group Name | Name of your runner group on StackGuardian | string |
| S3 Bucket Name | Storage bucket name from your runner group configuration | string |
| VPC ID | The VPC where runner instances will be deployed | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| API Region | Select your StackGuardian API region (EU1 - Europe, US1 - United States, or DASH - QA) | EU1 - Europe |
| Organization Name | Your organization name on StackGuardian | (auto-detected) |
| AWS Region | Target AWS region for deployment | eu-central-1 |
| Create Auto Scaling Group | Whether to create a new ASG or use an existing one | true |
| Existing ASG Name | Name of existing ASG when not creating new | (empty) |
| AMI ID | Custom AMI with pre-installed runner dependencies | (empty) |
| Runner Group Token | Authentication token for runner registration | (empty) |
| Storage Backend Role ARN | IAM role for S3 storage access | (empty) |
| Instance Type | EC2 instance type for runners | t3.xlarge |
| Global Prefix | Prefix for naming AWS resources | SG_RUNNER |
| Include Organization in Prefix | Add org name to resource names | false |
| Private Subnet ID | Private subnet for secure deployments | (empty) |
| Public Subnet ID | Public subnet for NAT Gateway | (empty) |
| Subnet ID | Subnet for runner instances (backwards compatible) | (empty) |
| Associate Public IP | Assign public IPs to instances | false |
| Create Network Infrastructure | Create NAT Gateway and routing | false |
| Proxy URL | HTTP proxy URL for private network deployments | (empty) |
| Additional Security Group IDs | Extra security groups to attach | (empty) |
| VPC Endpoint Security Group IDs | Security group IDs of VPC endpoints for HTTPS access | (empty) |
| Volume Type | EBS volume type (gp2, gp3, io1, io2) | gp3 |
| Volume Size (GB) | Storage size for runner instances (minimum 8GB) | 100 |
| Delete on Termination | Remove volume when instance terminates | false |
| SSH Key Name | Existing AWS SSH key pair name | (empty) |
| SSH Public Key | Custom SSH public key content | (empty) |
| SSH Access Rules | CIDR blocks allowed for SSH | (empty) |
| Additional Ingress Rules | Custom inbound security rules | (empty) |
| Minimum Size | Minimum number of runner instances (at least 1) | 1 |
| Maximum Size | Maximum number of runner instances | 3 |
| Desired Capacity | Initial number of instances | 1 |
| Scale Out Threshold | Queue depth triggering scale-out | 3 |
| Scale In Threshold | Queue depth triggering scale-in | 1 |
| Scale Out Step | Instances to add per scale-out | 1 |
| Scale In Step | Instances to remove per scale-in | 1 |
| Scale Out Cooldown (minutes) | Wait time between scale-out events (minimum 4) | 4 |
| Scale In Cooldown (minutes) | Wait time between scale-in events | 5 |
| Runner Startup Timeout | Seconds to wait for Docker to start | 300 |

## Important Notes

**AMI Requirement**: You must first create a custom AMI using the StackGuardian Packer template. This AMI contains Docker, the runner agent, and other required dependencies.

**Network Configuration**: For private subnet deployments, enable "Create Network Infrastructure" and provide both private and public subnet IDs. The template will create a NAT Gateway for internet connectivity.

**VPC Endpoints**: For fully private deployments without NAT Gateway, you can use VPC endpoints. Provide the security group IDs of your VPC endpoints (STS, SSM, ECR, etc.) in the "VPC Endpoint Security Group IDs" field. The template will add inbound rules to allow HTTPS traffic from the runners.

**Proxy Support**: If your network requires HTTP proxy for outbound connections, configure the "Proxy URL" field with your proxy address (e.g., http://proxy.example.com:8080).

**Scaling Behavior**: The auto-scaler monitors your job queue and adjusts capacity automatically. Scale-out happens when queued jobs reach the threshold (default: 3). Scale-in occurs when the queue is nearly empty (default: less than 1 job).

**Instance Access**: Runners are configured with AWS Systems Manager Session Manager for secure shell access without needing SSH keys. You can optionally configure SSH access using key pairs and CIDR rules.

## Outputs

| Output | Description |
|--------|-------------|
| Auto Scaling Group Name | Name of the created or configured ASG |
| Security Group ID | ID of the runner security group |
| IAM Role ARN | ARN of the EC2 instance role |
| NAT Gateway Public IP | Public IP of NAT Gateway (if created) |

## Security Features

- Encrypted root volumes for all instances
- IMDSv2 required for instance metadata access
- Session Manager access enabled (no SSH keys required)
- Restrictive security group with default deny inbound
- Private subnet deployment support with NAT Gateway
- VPC endpoint integration for fully private deployments
- IAM roles with least-privilege permissions
