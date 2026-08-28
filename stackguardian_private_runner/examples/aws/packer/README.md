# StackGuardian Private Runner — AWS AMI Build

Builds the runner AMI and nothing else. No runner group, no connector, no EC2
instance — just the image, so you can bake it once and point other deployments at
the resulting `ami_id`.

> For a full working runner in one apply, use
> [examples/aws/quickstart](../quickstart/) instead — it wires this same module
> together with the runner group and an EC2 runner.

## What Gets Built

```
tofu apply
    |
    v
[Look up your VPC + subnet]  data.aws_vpc / data.aws_subnet   (read only)
    |
    v
[Packer build]  null_resource.packer_build
    |   temporary EC2 instance in your subnet, removed when the build ends
    |   installs: Docker, jq, cron, unzip, sg-runner
    |   optional: Terraform and/or OpenTofu at the versions you name
    v
[Record the AMI ID]  terraform_data.ami_id  ->  output ami_id
```

Only the AMI persists. The build instance, its key pair and its security group
are created and destroyed by Packer within the run.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| **OpenTofu >= 1.4** (or Terraform >= 1.4) | The module uses `terraform_data` |
| **AWS credentials** | Via `AWS_PROFILE`, environment variables, or an instance role |
| **An existing VPC and subnet** | This example attaches to them; it does not create networking |
| **Outbound internet from that subnet** | The build downloads packages and release archives |
| `sh`, `curl`, `unzip` | Used to bootstrap Packer at `packer_config.version` |

Packer itself is downloaded automatically — you do not need it installed.

## Quick Start

```bash
cp terraform.tfvars.tpl terraform.tfvars
$EDITOR terraform.tfvars     # set network.vpc_id and network.subnet_id
tofu init
tofu apply
tofu output ami_id
```

The build takes several minutes. Once it finishes, the AMI ID is recorded in
state and every later plan is a no-op — see [Rebuilding](#rebuilding).

## Configuration

### Required

| Variable | Type | Description |
|----------|------|-------------|
| `network.vpc_id` | `string` | Existing VPC ID |
| `network.subnet_id` | `string` | Existing subnet the build instance runs in |

### Commonly Adjusted

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `eu-central-1` | An AMI is regional — build it where you intend to launch runners |
| `instance_type` | `t3.medium` | Build instance size |
| `network.private_subnet` | `false` | Set `true` for a private subnet — see below |
| `os.family` | `amazon` | `amazon`, `ubuntu`, or `rhel` |
| `os.version` | `""` | Required for `ubuntu` and `rhel` |
| `ami_name_prefix` | `SG-RUNNER-ami` | Prefix of the generated AMI name |
| `terraform.primary_version` | `""` | Installed as `/bin/terraform` |
| `opentofu.primary_version` | `""` | Installed as `/bin/tofu` |
| `sg_runner.pre_release` | `false` | Bake the newest sg-runner pre-release instead of latest stable |

Everything under `os`, `terraform`, `opentofu` and `sg_runner` is baked in at
build time, so changing any of them has **no effect on an existing AMI** until
you trigger a rebuild.

### Public vs Private Subnet

By default the build instance gets a public IP and Packer connects to it over the
internet. Set `network.private_subnet = true` when your subnet is private —
Packer then connects over the **private IP**, which means whatever runs OpenTofu
must have a route into that subnet (VPN, Direct Connect, or running from inside
the VPC). Either way the subnet needs outbound internet access for the build to
download anything.

## Rebuilding

The AMI is built **once per state**. Later plans reuse the recorded ID, so the
AMI stays stable and downstream deployments are not disturbed.

| Situation | Result |
|-----------|--------|
| First apply | Packer builds; the AMI ID is recorded in state |
| Every plan/apply after that | No build, no diff |
| `packer_config.rebuild_ami_token` changed | Packer builds a new AMI, once |
| State destroyed and re-applied | Packer builds again |

```hcl
packer_config = {
  rebuild_ami_token = "2026-08-25-tofu-1.11"   # any new value
}
```

The token is a free-form string rather than a boolean on purpose: bump it to
rebuild, then leave it alone. A boolean would rebuild again the moment you unset it.

## Outputs

| Output | Description |
|--------|-------------|
| `ami_id` | The built AMI, recorded in state — feed this to `aws/single_runner` or `aws/autoscaling_group` |
| `ami_info` | Region, OS, name pattern, deregistration protection and cleanup settings |
| `cleanup_commands` | Ready-to-run AWS CLI commands for inspecting or removing the AMI by hand |
| `subnet_id` | The existing subnet the build ran in |

## Destroying

```bash
tofu destroy
```

With `packer_config.cleanup_amis_on_destroy` (default `true`) this deregisters the
AMI this deployment built, and deletes its snapshots when `delete_snapshots` is
also true. AMIs from other deployments are never touched. Set it to `false` to
keep the image after tearing down the state.

> Deregistering an AMI that other deployments still reference will break their
> next instance launch. Check `ami_id` before destroying.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Plan fails reading the VPC or subnet | `network.vpc_id` / `network.subnet_id` does not exist, or credentials lack `ec2:Describe*` |
| `Resource postcondition failed` on the subnet | `network.subnet_id` is in a different VPC than `network.vpc_id` |
| Packer fails immediately | No outbound path from the subnet, or missing EC2 permissions |
| Packer hangs connecting to the instance | Private subnet without `network.private_subnet = true`, or no route from here into a private subnet |
| `No AMI recorded` on output | The build produced no AMI — check `../../../aws/packer/packer_manifest.log` |
| Packer never re-runs | Working as designed; bump `rebuild_ami_token` |

To force a rebuild without touching variables:

```bash
tofu apply -replace=module.packer.null_resource.packer_build
```

## Notes

- The provisioning script is shared with the Azure build:
  [`packer/scripts/setup.sh`](../../../packer/scripts/setup.sh). A fix there lands
  on both clouds.
- No backend is configured. The recorded AMI ID lives in local state, so keep it
  if you want later plans to skip the build.
