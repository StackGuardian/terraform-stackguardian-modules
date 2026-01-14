# StackGuardian Private Runner - AWS Full Stack Template

Deploy a complete auto-scaling StackGuardian Private Runner infrastructure on AWS using the StackGuardian platform.

## Overview

This Stack deploys a production-ready private runner environment with custom AMI building, auto-scaling EC2 instances, and intelligent Lambda-based scaling. The Stack orchestrates four templates that work together to provide a fully managed, self-healing runner infrastructure.

### What This Stack Creates

- **Custom AMI** with pre-installed Docker, Terraform, OpenTofu, and StackGuardian runner components
- **Runner Group** on StackGuardian platform with S3 storage backend and AWS connector
- **Auto Scaling Group** with EC2 instances that automatically register as runners
- **Lambda Autoscaler** that monitors job queues and adjusts capacity based on workload demand
- **Network Infrastructure** (optional) including NAT Gateway and route tables for private deployments
- **IAM Roles** for EC2 instances, Lambda function, and S3 storage backend access

## Prerequisites

- StackGuardian organization API key (`sgo_*` or `sgu_*`)
- AWS account with appropriate IAM permissions
- Existing VPC with subnets (public and/or private)
- Internet access for runner instances (via NAT Gateway, Internet Gateway, or proxy)

---

## Template 1: Packer AMI Builder

Build a custom AMI for StackGuardian Private Runner with pre-installed dependencies.

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| aws_region | AWS region where the AMI will be built | select |
| network.vpc_id | Existing VPC ID where Packer will build the AMI | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| instance_type | EC2 instance type for the Packer build process | `t3.medium` |
| network.private_subnet_id | Private subnet ID for the build instance | `""` |
| network.public_subnet_id | Public subnet ID for the build instance | `""` |
| network.proxy_url | Proxy URL for internet access in private networks | `""` |
| os.family | Base operating system family (amazon, ubuntu, rhel) | `amazon` |
| os.version | OS version (required for Ubuntu/RHEL) | - |
| os.update_os_before_install | Update OS packages before installing components | `true` |
| os.ssh_username | SSH username (auto-detected if empty) | `""` |
| os.user_script | Custom shell script to execute during provisioning | `""` |
| packer_config.version | Packer version to use | `1.14.1` |
| packer_config.deregistration_protection.enabled | Enable AMI deregistration protection | `true` |
| packer_config.deregistration_protection.with_cooldown | Enable cooldown period before deregistration | `false` |
| packer_config.delete_snapshots | Delete EBS snapshots during cleanup | `true` |
| packer_config.cleanup_amis_on_destroy | Auto-delete AMIs on terraform destroy | `true` |
| terraform.primary_version | Primary Terraform version to install | `""` |
| terraform.additional_versions | Additional Terraform versions to install | `[]` |
| opentofu.primary_version | Primary OpenTofu version to install | `""` |
| opentofu.additional_versions | Additional OpenTofu versions to install | `[]` |

### Outputs

| Output | Description |
|--------|-------------|
| ami_id | The ID of the created AMI |
| ami_info | Comprehensive AMI information for tracking |

---

## Template 2: Runner Group

Create a StackGuardian Runner Group with S3 storage backend and AWS connector.

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| stackguardian.api_key | Your organization's API key (`sgo_*`/`sgu_*`) or secret reference | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| stackguardian.api_uri | StackGuardian platform region | `EU1 - Europe` |
| stackguardian.org_name | Your organization name | (from environment) |
| aws_region | Target AWS region for S3 and IAM resources | `eu-central-1` |
| create_storage_backend | Whether to create a new S3 bucket | `true` |
| existing_s3_bucket_name | Existing S3 bucket name (when create_storage_backend is false) | - |
| force_destroy_storage_backend | Force destroy S3 bucket on module destruction | `false` |
| override_names.global_prefix | Prefix for naming all resources | `SG_RUNNER` |
| override_names.include_org_in_prefix | Append organization name to prefix | `false` |
| override_names.runner_group_name | Override the runner group name | (auto-generated) |
| override_names.connector_name | Override the connector name | (auto-generated) |
| max_runners | Maximum number of runners allowed | `3` |

### Outputs

| Output | Description |
|--------|-------------|
| runner_group_name | Name of the StackGuardian runner group |
| runner_group_token | Token for runner registration (sensitive) |
| s3_bucket_name | Name of the S3 bucket for storage backend |
| storage_backend_role_arn | ARN of the IAM role for S3 access |
| connector_name | Name of the StackGuardian connector |

---

## Template 3: Autoscaling Group

Deploy an Auto Scaling Group with EC2 instances configured as StackGuardian runners.

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| stackguardian.api_key | Your organization's API key | string |
| runner_group_name | Runner group name (from runner_group template) | string |
| s3_bucket_name | S3 bucket name (from runner_group template) | string |
| network.vpc_id | Existing VPC ID for deployment | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| stackguardian.api_uri | StackGuardian platform region | `EU1 - Europe` |
| stackguardian.org_name | Your organization name | (from environment) |
| aws_region | Target AWS region for deployment | `eu-central-1` |
| create_asg | Create new Auto Scaling Group (false to use existing) | `true` |
| existing_asg_name | Existing ASG name (when create_asg is false) | - |
| ami_id | AMI ID with pre-installed dependencies (from packer template) | `""` |
| runner_group_token | Runner group token (from runner_group template) | `""` |
| storage_backend_role_arn | IAM role ARN for S3 access (from runner_group template) | `""` |
| instance_type | EC2 instance type for runners | `t3.xlarge` |
| override_names.global_prefix | Prefix for naming all resources | `SG_RUNNER` |
| override_names.include_org_in_prefix | Append organization name to prefix | `false` |
| network.private_subnet_id | Private subnet ID for runner instances | `""` |
| network.public_subnet_id | Public subnet ID (for NAT Gateway) | `""` |
| network.associate_public_ip | Assign public IPs to runner instances | `false` |
| network.create_network_infrastructure | Create NAT Gateway and route tables | `false` |
| network.proxy_url | HTTP proxy URL for private networks | `""` |
| network.additional_security_group_ids | Additional security groups to attach | `[]` |
| network.vpc_endpoint_security_group_ids | Security groups of VPC endpoints | `[]` |
| volume.type | EBS volume type | `gp3` |
| volume.size | EBS volume size in GB | `100` |
| volume.delete_on_termination | Delete EBS volume on instance termination | `false` |
| firewall.ssh_key_name | Name of existing SSH key pair | `""` |
| firewall.ssh_public_key | Custom SSH public key content | `""` |
| firewall.ssh_access_rules | Map of CIDR blocks for SSH access | `{}` |
| firewall.additional_ingress_rules | Additional ingress rules | `{}` |
| scaling.min_size | Minimum number of runner instances | `1` |
| scaling.max_size | Maximum number of runner instances | `3` |
| scaling.desired_capacity | Initial desired number of instances | `1` |
| runner_startup_timeout | Max seconds to wait for Docker to start | `300` |

### Outputs

| Output | Description |
|--------|-------------|
| autoscaling_group_name | Name of the Auto Scaling Group |
| launch_template_id | ID of the Launch Template |
| security_group_id | ID of the security group |
| iam_role_arn | ARN of the EC2 IAM role |
| nat_gateway_public_ip | Public IP of NAT Gateway (if created) |

---

## Template 4: Autoscaler

Deploy a Lambda-based autoscaler that monitors job queues and scales the ASG.

### Required Parameters

| Parameter | Description | Type |
|-----------|-------------|------|
| stackguardian.api_key | Your organization's API key | string |
| asg_name | Auto Scaling Group name (from autoscaling_group template) | string |
| runner_group_name | Runner group name (from runner_group template) | string |
| s3_bucket_name | S3 bucket name (from runner_group template) | string |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| stackguardian.api_uri | StackGuardian platform region | `EU1 - Europe` |
| stackguardian.org_name | Your organization name | (from environment) |
| runner_type | Runner type (external or shared-external) | `external` |
| aws_region | Target AWS region for Lambda deployment | `eu-central-1` |
| override_names.global_prefix | Prefix for naming all resources | `SG_RUNNER` |
| override_names.include_org_in_prefix | Append organization name to prefix | `false` |
| scaling.min_size | Minimum number of runners to maintain | `1` |
| scaling.scale_out_threshold | Queued jobs to trigger scale-out | `3` |
| scaling.scale_in_threshold | Queued jobs below which to trigger scale-in | `1` |
| scaling.scale_out_step | Instances to add when scaling out | `1` |
| scaling.scale_in_step | Instances to remove when scaling in | `1` |
| scaling.scale_out_cooldown_duration | Minutes to wait after scale-out | `4` |
| scaling.scale_in_cooldown_duration | Minutes to wait after scale-in | `5` |
| lambda_config.runtime | Python runtime version | `python3.11` |
| lambda_config.timeout | Lambda timeout in seconds | `60` |
| lambda_config.memory_size | Lambda memory size in MB | `128` |
| autoscaler_repo.url | Git repository URL for autoscaler code | `https://github.com/StackGuardian/sg-runner-autoscaler` |
| autoscaler_repo.branch | Git branch for autoscaler code | `main` |

### Outputs

| Output | Description |
|--------|-------------|
| lambda_function_name | Name of the Lambda autoscaler function |
| lambda_function_arn | ARN of the Lambda function |
| scheduler_name | Name of the EventBridge Scheduler |
| log_group_name | CloudWatch Log Group for Lambda logs |

---

## Important Notes

**Deployment Order**: Templates must be deployed in sequence:
1. **Packer** - Build the AMI first
2. **Runner Group** - Create the runner group and storage backend
3. **Autoscaling Group** - Deploy EC2 instances using outputs from templates 1 and 2
4. **Autoscaler** - Deploy Lambda autoscaler using outputs from templates 2 and 3

**Network Requirements**: Runner instances need outbound internet access to communicate with StackGuardian API and download packages. Options include:
- Public subnet with Internet Gateway
- Private subnet with NAT Gateway (use `create_network_infrastructure = true`)
- Private subnet with HTTP proxy

**API Key Security**: Use `${secret::SECRET_NAME}` format to reference secrets stored in StackGuardian instead of hardcoding API keys.

**Scaling Behavior**: The Lambda autoscaler runs every minute and adjusts ASG capacity based on job queue depth. Cooldown periods prevent rapid scaling oscillation.

---

## Security Features

- AMI deregistration protection to prevent accidental deletion
- IAM roles with least-privilege permissions
- S3 bucket encryption and secure cross-account access
- Security groups with minimal required ingress rules
- VPC endpoint support for private deployments
- Optional SSH access with configurable CIDR restrictions
