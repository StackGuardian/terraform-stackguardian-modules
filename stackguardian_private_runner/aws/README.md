# StackGuardian Private Runner - AWS Template

Deploy a StackGuardian Private Runner on AWS with auto-scaling capabilities.

## What This Template Creates

- **Auto Scaling Group** with EC2 instances running the StackGuardian runner
- **Lambda-based autoscaler** that scales runners based on job queue metrics
- **S3 storage backend** for Terraform state and artifacts with encryption
- **Security groups** and networking configuration
- **StackGuardian Runner Group and Connector** for platform integration

## Prerequisites

1. **StackGuardian API Key** - Generate from your organization settings
2. **AWS Permissions** - Your AWS account needs sufficient permissions (see `aws_permissions.json`)
3. **Custom AMI** - AMI with required dependencies: docker, cron, jq, sg-runner
4. **VPC Infrastructure** - Existing VPC with at least one public subnet

## Template Parameters

### Required Configuration

**StackGuardian Settings**

- `stackguardian.api_key` - Your StackGuardian API key (required, starts with `sgu_`)
- `stackguardian.org_name` - Your organization name (optional, defaults to API key organization)

**AWS Configuration**

- `aws_region` - Target AWS region for deployment
- `ami_id` - AMI ID with runner dependencies (must start with `ami-`)

**Network Settings**

- `network.vpc_id` - Your existing VPC ID (required)
- `network.public_subnet_id` - Public subnet for runner instances (required)
- `network.private_subnet_id` - Optional private subnet for enhanced security
- `network.associate_public_ip` - Whether instances get public IPs (default: false)

### Optional Configuration

**Instance Settings**

- `instance_type` - EC2 instance type (default: t3.xlarge, minimum 4 vCPU/8GB RAM recommended)

**Storage Configuration**

- `volume.type` - EBS volume type: gp2, gp3, io1, io2 (default: gp3)
- `volume.size` - Volume size in GB (required, default: 100, minimum: 8)
- `volume.delete_on_termination` - Delete volume when instance terminates (default: false)

**Resource Naming**

- `override_names.global_prefix` - Prefix for all resource names (required, default: SG_RUNNER)
- `override_names.runner_group_name` - Custom name for the runner group (optional)
- `override_names.connector_name` - Custom name for the connector (optional)

**Security & Access**

- `firewall.ssh_key_name` - EC2 Key Pair name for SSH access (optional)
- `firewall.ssh_public_key` - SSH public key content (alternative to key name)
- `firewall.allow_ssh_cidr_blocks` - IP ranges allowed SSH access (optional, array)
- `firewall.additional_ingress_rules` - Custom firewall rules for additional ports (optional, array)

**Auto-scaling Behavior**

- `scaling.min_runners` - Minimum number of runner instances (default: 1, minimum: 1)
- `scaling.scale_out_threshold` - Scale out when queue exceeds this many jobs (default: 3)
- `scaling.scale_in_threshold` - Scale in when queue drops below this many jobs (default: 2)
- `scaling.scale_out_cooldown_duration` - Minutes to wait before scaling out again (default: 4, minimum: 4)
- `scaling.scale_in_cooldown_duration` - Minutes to wait before scaling in again (default: 5)
- `scaling.scale_out_step` - Instances to add per scale-out event (default: 1)
- `scaling.scale_in_step` - Instances to remove per scale-in event (default: 1)

**Advanced Settings**

- `force_destroy_storage_backend` - Allow destroying S3 bucket with data (default: false)
- `image.repository` - Docker image repository for autoscaler Lambda (default: StackGuardian ECR repository)
- `image.tag` - Docker image tag (default: latest)

## Important Notes

**AMI Requirements**: Your AMI must include docker, cron, jq, and the sg-runner binary. Use the StackGuardian Packer template for best results.

**Network Security**: Runners need outbound HTTPS (port 443) access to communicate with StackGuardian. Private subnet deployment requires NAT Gateway or similar for internet access.

**Auto-scaling**: The Lambda function monitors your StackGuardian job queue and automatically adjusts the number of running instances based on demand.

## After Deployment

The template creates a Runner Group that will appear in your StackGuardian organization. Use the Runner Group name (from outputs) when configuring workflows to execute on your private infrastructure.

**Key Outputs:**

- `runner_group_name` - Use this name in workflow configurations
- `runner_group_url` - Direct link to manage runners in StackGuardian
- `storage_backend_name` - S3 bucket for state storage

## Security Features

- S3 bucket with encryption at rest and versioning enabled
- Security groups restrict access to necessary ports only
- IAM roles follow least-privilege principles
- Optional private subnet deployment for network isolation

---

This template integrates seamlessly with StackGuardian workflows - simply select the created Runner Group when configuring your infrastructure deployments.

