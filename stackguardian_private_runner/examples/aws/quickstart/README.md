# StackGuardian Private Runner - AWS Quickstart

Zero to a registered, running Private Runner on AWS in a single `apply`.

This example wires the three building-block modules together into one root module,
so you configure a handful of values once instead of running three deployments and
hand-copying outputs between them.

> Deploying a single runner on a **public subnet**. For an autoscaled fleet, use
> the `aws/autoscaling_group` and `aws/autoscaler` modules directly - see the
> [top-level README](../../../README.md).

## Contents

- [What Gets Deployed](#what-gets-deployed)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [How the AMI Lifecycle Works](#how-the-ami-lifecycle-works)
- [Networking](#networking)
- [Outputs](#outputs)
- [Accessing the Runner](#accessing-the-runner)
- [Day-2 Operations](#day-2-operations)
- [Destroying](#destroying)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)

## What Gets Deployed

```
                     ┌──────────────────────────────┐
  module.runner_group│  StackGuardian control plane │
  ──────────────────►│  • runner group              │
        │            │  • connector                 │
        │            └──────────────────────────────┘
        │            ┌──────────────────────────────┐
        └───────────►│  AWS (storage backend)       │
                     │  • S3 bucket + CORS + PAB    │
                     │  • IAM role (assumed by      │
                     │    the runner for S3 access) │
                     └──────────────────────────────┘
                                    │
                                    │ runner_group_name
                                    │ runner_group_token
                                    │ storage_backend_role_arn
                                    ▼
  module.packer      ┌──────────────────────────────┐
  ──────────────────►│  Packer build (first apply)  │
                     │  • temp EC2 build instance   │
                     │    (auto-terminated)         │
                     │  • custom AMI: Docker, jq,   │
                     │    cron, sg-runner, and      │
                     │    optional Terraform/Tofu   │
                     └──────────────────────────────┘
                                    │
                                    │ ami_id
                                    ▼
  module.single_runner
                     ┌──────────────────────────────┐
                     │  Runner EC2 instance         │
                     │  • security group            │
                     │    (egress-all, no inbound   │
                     │     unless SSH configured)   │
                     │  • IAM role + instance       │
                     │    profile (SSM + assume     │
                     │    the S3 role above)        │
                     │  • optional EC2 key pair     │
                     └──────────────────────────────┘
```

The runner registers itself with the StackGuardian platform on first boot using the
runner group token, then starts polling for work.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| **OpenTofu >= 1.6** (or Terraform >= 1.4) | The packer module uses `terraform_data` |
| **Packer** | Installed automatically by the build script at the configured version |
| **AWS credentials** | Via `AWS_PROFILE`, environment variables, or instance role |
| **StackGuardian API key** | Org-scoped key with permission to create runner groups and connectors |
| **VPC** | Existing, with a working outbound internet path |
| **Public subnet** | Used for both the Packer build instance and the runner |

### AWS Permissions

The identity running this needs, at minimum:

- **EC2**: `RunInstances`, `TerminateInstances`, `CreateImage`, `DeregisterImage`,
  `DescribeImages`, `DescribeInstances`, `CreateTags`, `ModifyImageAttribute`,
  `CreateSnapshot`, `DeleteSnapshot`, plus security-group and key-pair management
- **IAM**: `CreateRole`, `CreatePolicy`, `AttachRolePolicy`, `CreateInstanceProfile`,
  `PassRole`
- **S3**: `CreateBucket`, `PutBucketPolicy`, `PutBucketCors`, `PutPublicAccessBlock`
- **STS**: `GetCallerIdentity`

## Quick Start

**1. Copy the template and fill it in**

```bash
cp terraform.tfvars.tpl terraform.tfvars
$EDITOR terraform.tfvars
```

At minimum you must set `stackguardian.api_key`, `stackguardian.org_name`,
`vpc_id`, and `public_subnet_id`.

**2. Initialize**

```bash
tofu init
```

**3. Review the plan**

```bash
tofu plan -out=tfplan
```

**4. Apply**

```bash
tofu apply tfplan
```

The first apply builds the AMI, which dominates the runtime - expect several
minutes before the runner instance itself is created. Later applies skip the build
entirely (see [AMI lifecycle](#how-the-ami-lifecycle-works)).

**5. Confirm the runner came up**

```bash
tofu output runner_group_url
```

Open that URL; the runner should appear as active in the runner group within a
minute or two of the instance booting.

## Configuration

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `stackguardian.api_key` | `string` | StackGuardian API key (sensitive) |
| `stackguardian.org_name` | `string` | StackGuardian organization name |
| `vpc_id` | `string` | Existing VPC ID |
| `public_subnet_id` | `string` | Public subnet for the build instance and runner |

### Commonly Adjusted

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `eu-central-1` | Region for all AWS resources |
| `stackguardian.api_uri` | `https://api.app.stackguardian.io` | Platform endpoint - see note below |
| `vpc_endpoint_security_group_ids` | `[]` | Interface-endpoint SGs to open on 443 - see [Networking](#networking) |
| `runner_instance_type` | `t3.xlarge` | Runner instance size |
| `packer_instance_type` | `t3.medium` | Build instance size |
| `max_runners` | `3` | Max runners in the runner group |
| `override_names.global_prefix` | `SG_RUNNER` | Prefix for created resource names |
| `runner_startup_timeout` | `300` | Seconds to wait for Docker before self-shutdown |
| `force_destroy_storage_backend` | `false` | If `true`, `destroy` also deletes S3 contents |

> **`api_uri` must be one of three known values.** The runner group module maps the
> API host to its matching web-console host to build the console URL and the S3 CORS
> origin. Supported values are `https://api.app.stackguardian.io` (EU1),
> `https://api.us.stackguardian.io` (US1), and `https://testapi.qa.stackguardian.io`
> (QA). Any other value fails the plan with a map-lookup error.

### AMI Contents

| Variable | Default | Description |
|----------|---------|-------------|
| `os.family` | `amazon` | `amazon`, `ubuntu`, or `rhel` |
| `os.version` | `""` | Required for `ubuntu` / `rhel` |
| `os.update_os_before_install` | `true` | Patch the OS before installing |
| `os.user_script` | `""` | Extra shell run after standard setup |
| `terraform.primary_version` | `""` | Installed as `/bin/terraform` |
| `terraform.additional_versions` | `[]` | Installed as `/bin/terraform<version>` |
| `opentofu.primary_version` | `""` | Installed as `/bin/tofu` |
| `opentofu.additional_versions` | `[]` | Installed as `/bin/tofu<version>` |
| `sg_runner.pre_release` | `false` | Bake the newest sg-runner pre-release instead of latest stable |

Every one of these is baked into the image at build time, so changing any of them
on an existing deployment has **no effect until you trigger a rebuild**.

### Full Variable Reference

See [`variables.tf`](variables.tf) - every variable is documented there, and
[`terraform.tfvars.tpl`](terraform.tfvars.tpl) shows each one with its default.

## How the AMI Lifecycle Works

Building an AMI takes minutes, so the packer module builds **once per state** and
reuses what it built:

| Situation | Result |
|-----------|--------|
| First apply | Packer builds the AMI; its ID is recorded in state |
| Every plan/apply after that | No build, no diff - the ID comes from state |
| `packer_config.rebuild_ami_token` changed | Packer builds a new AMI, once |
| State destroyed and re-applied | Packer builds again |

To force a fresh build - after changing the OS, `user_script`, tool versions, or
the sg-runner channel:

```hcl
packer_config = {
  version           = "1.14.1"
  rebuild_ami_token = "2026-08-24-tofu-1.11"   # any new value
}
```

The token is a free-form string rather than a boolean on purpose: bump it to
rebuild, then leave it alone. A boolean would rebuild again the moment you unset it.

Because the AMI ID is now stable across applies, **the runner instance is no longer
replaced on every apply**. A rebuild does replace it, since the instance's AMI
changes.

> `packer_config.cleanup_amis_on_destroy` (default `true`) only ever touches the
> AMI this deployment built - on destroy, and on the rebuild that supersedes it.
> AMIs from other deployments are never deregistered.

## Networking

This example places both the Packer build instance and the runner on the **public
subnet** you provide, with a public IP attached, and relies on the subnet's route
to an internet gateway for outbound access.

The runner's security group allows **all egress** and **no ingress** by default.
SSH is opened only if you set `firewall.ssh_access_rules`.

### VPC Interface Endpoints

If your VPC resolves AWS APIs through interface endpoints (STS, EC2, SSM, ECR)
rather than over the internet, you **must** list those endpoints' security groups:

```hcl
vpc_endpoint_security_group_ids = ["sg-0123456789abcdef0"]
```

The module adds an inbound HTTPS (443) rule to each listed security group, sourced
from the runner's own security group.

Leaving this empty in an endpoint-backed VPC is a quiet failure: the endpoint drops
the runner's traffic, and jobs **hang on plan** rather than returning an error. If
you see runners stuck with no logs, check this first.

## Outputs

| Output | Description |
|--------|-------------|
| `runner_group_name` | Name of the created runner group |
| `runner_group_url` | Direct link to the runner group in the web console |
| `connector_name` | Name of the created connector |
| `s3_bucket_name` | S3 bucket backing the runner group's storage |
| `ami_id` | AMI built by Packer and recorded in state |
| `instance_id` | Runner EC2 instance ID |
| `instance_public_ip` | Runner public IP |
| `instance_private_ip` | Runner private IP |
| `security_group_id` | Runner security group ID |

The runner group token is deliberately **not** exposed as a root output. It is
passed module-to-module in memory and marked sensitive.

## Accessing the Runner

**Session Manager (recommended).** The instance role includes
`AmazonSSMManagedInstanceCore`, so no inbound access is needed:

```bash
aws ssm start-session --target "$(tofu output -raw instance_id)"
```

**SSH.** Requires opening the security group first:

```hcl
firewall = {
  ssh_public_key   = "ssh-ed25519 AAAA..."
  ssh_access_rules = { "my-ip" = "203.0.113.10/32" }
}
```

Useful checks once you are on the box:

```bash
sudo tail -f /var/log/sg_runner_startup.log   # registration + startup
sudo tail -f /var/log/cloud-init-output.log   # full user-data run
docker ps                                     # job containers
systemctl status docker                       # runner depends on this
cat /etc/sg-runner.conf                       # baked-in release channel
```

> `sg-runner` is a shell script at `/usr/bin/sg-runner`, not a systemd service.
> It is invoked once from user-data as `sg-runner register ...`, so there is no
> `systemctl status sg-runner` or `journalctl -u sg-runner` to check.

## Day-2 Operations

**Update the sg-runner binary in place** (no rebuild, no Terraform):

```bash
sudo sg-runner-update
```

**Change what is baked into the image** - edit `os`, `terraform`, `opentofu`, or
`sg_runner`, then bump `packer_config.rebuild_ami_token` and apply. This replaces
the AMI *and* the runner instance.

**Resize the runner** - change `runner_instance_type` and apply. No rebuild needed.

**Test an upcoming runner release:**

```hcl
sg_runner     = { pre_release = true }
packer_config = { version = "1.14.1", rebuild_ami_token = "prerelease-test" }
```

Falls back to the latest stable release if no pre-release is published. Not
recommended for production.

## Destroying

```bash
tofu destroy
```

This deregisters the AMI and deletes its snapshots (unless
`cleanup_amis_on_destroy` or `delete_snapshots` is disabled), removes the runner
group and connector from StackGuardian, and tears down the AWS resources.

> The S3 bucket is **retained if it still has objects**, unless you set
> `force_destroy_storage_backend = true`. That default is intentional - the bucket
> holds Terraform state for jobs the runner executed.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Jobs hang on plan, no logs | VPC interface endpoints not listed in `vpc_endpoint_security_group_ids` |
| Plan fails on a map lookup | `stackguardian.api_uri` is not one of the three supported values |
| Packer fails immediately | Subnet has no outbound internet path, or IAM permissions are missing |
| `No AMI recorded` on output | The build produced no AMI - check `../../../aws/packer/packer_manifest.log` |
| Packer never re-runs | Working as designed; bump `rebuild_ami_token` |
| Runner shuts itself down after boot | Docker did not start within `runner_startup_timeout` - user-data calls `shutdown -h now` on timeout |
| Runner never appears in the console | Token or org name wrong; check `/var/log/sg_runner_startup.log` |

To force a rebuild without touching variables:

```bash
tofu apply -replace=module.packer.null_resource.packer_build
```

## Limitations

This example trades flexibility for a short path to a working runner:

- **Public subnet only.** `private_subnet_id`, `create_network_infrastructure`
  (NAT gateway), and `proxy_url` are supported by the underlying modules but are
  not exposed here. Use `aws/single_runner` directly for private deployments.
- **Single runner.** No autoscaling; `max_runners` caps the runner group, not the
  instance count.
- **Local state.** No backend is configured. Add one before using this for anything
  you intend to keep.
- **Creates a new runner group.** It does not attach to an existing one.
