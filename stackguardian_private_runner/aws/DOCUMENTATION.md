# StackGuardian Private Runner - AWS Template

Deploy a StackGuardian Private Runner on AWS with auto-scaling capabilities and complete platform integration.

## Overview

This template creates a StackGuardian Private Runner infrastructure on AWS with auto-scaling capabilities, enabling secure execution of workflows in your private environment.

### What This Template Creates

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

### Required Parameters

| Parameter                  | Description                                    | Type     |
| -------------------------- | ---------------------------------------------- | -------- |
| `stackguardian.api_key`    | StackGuardian API key (must start with `sgu_`) | `string` |
| `aws_region`               | Target AWS region for deployment               | `string` |
| `ami_id`                   | AMI ID with runner dependencies               | `string` |
| `network.vpc_id`           | Existing VPC ID                               | `string` |
| `network.public_subnet_id` | Public subnet for runner instances            | `string` |

### Optional Parameters

| Parameter                                       | Description                                    | Default      |
| ----------------------------------------------- | ---------------------------------------------- | ------------ |
| `stackguardian.org_name`                        | Organization name (auto-derived from API key) | `""`         |
| `instance_type`                                 | EC2 instance type                             | `t3.xlarge`  |
| `volume.type`                                   | EBS volume type (gp2/gp3/io1/io2)            | `gp3`        |
| `volume.size`                                   | Volume size in GB                             | `100`        |
| `volume.delete_on_termination`                  | Delete volume when instance terminates        | `false`      |
| `override_names.global_prefix`                  | Prefix for all resource names                 | `SG_RUNNER`  |
| `override_names.runner_group_name`              | Custom runner group name                      | `""`         |
| `override_names.connector_name`                 | Custom connector name                         | `""`         |
| `firewall.ssh_key_name`                         | EC2 Key Pair name for SSH access             | `""`         |
| `firewall.ssh_public_key`                       | SSH public key content                        | `""`         |
| `firewall.ssh_access_rules`                     | IP ranges allowed SSH access                  | `{}`         |
| `firewall.additional_ingress_rules`             | Custom firewall rules                         | `{}`         |
| `scaling.min_runners`                           | Minimum number of runner instances            | `1`          |
| `scaling.scale_out_threshold`                   | Scale out threshold (jobs)                    | `3`          |
| `scaling.scale_in_threshold`                    | Scale in threshold (jobs)                     | `1`          |
| `scaling.scale_out_cooldown_duration`           | Scale out cooldown (minutes)                  | `4`          |
| `scaling.scale_in_cooldown_duration`            | Scale in cooldown (minutes)                   | `5`          |
| `scaling.scale_out_step`                        | Instances to add per scale-out                | `1`          |
| `scaling.scale_in_step`                         | Instances to remove per scale-in              | `1`          |
| `force_destroy_storage_backend`                 | Allow destroying S3 bucket with data         | `false`      |

## Important Notes

**AMI Requirements**: Your AMI must include docker, cron, jq, and the sg-runner binary. Use the StackGuardian Packer template for best results.

**Network Security**: Runners need outbound HTTPS (port 443) access to communicate with StackGuardian. Private subnet deployment requires NAT Gateway or similar for internet access.

**Auto-scaling**: The Lambda function monitors your StackGuardian job queue and automatically adjusts the number of running instances based on demand. Default thresholds are 3 jobs to scale out and 1 job to scale in.

## Outputs

| Output                   | Description                         |
| ------------------------ | ----------------------------------- |
| `runner_group_name`      | Use this name in workflow configurations |
| `runner_group_url`       | Direct link to manage runners in StackGuardian |
| `storage_backend_name`   | S3 bucket for state storage        |
| `autoscaling_group_name` | Auto Scaling Group name            |
| `lambda_function_name`   | Lambda autoscaler function name    |

## Security Features

- S3 bucket with encryption at rest and versioning enabled
- Security groups restrict access to necessary ports only
- IAM roles follow least-privilege principles
- Optional private subnet deployment for network isolation

## Usage

After deployment, the template creates a Runner Group that will appear in your StackGuardian organization. Use the Runner Group name (from outputs) when configuring workflows to execute on your private infrastructure.

This template integrates seamlessly with StackGuardian workflows - simply select the created Runner Group when configuring your infrastructure deployments.

