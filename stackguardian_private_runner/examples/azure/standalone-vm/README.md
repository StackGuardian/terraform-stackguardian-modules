# StackGuardian Private Runner - Azure Standalone VM

A single-file reproduction rig: a stock Azure Marketplace RHEL VM that installs Docker and
`sg-runner` on first boot, then registers with a StackGuardian runner group.

It composes only the `runner_group` module. Everything else - VNet, subnet, NSG, public IP, NIC
and the `azurerm_linux_virtual_machine` - is declared inline here, and the runner software is
installed at boot by [`templates/install_runner.sh.tpl`](templates/install_runner.sh.tpl).

## When to use this instead of the quickstart

Use [`../quickstart`](../quickstart) for anything you intend to keep. It composes the real
`azure/packer` and `azure/azure_runner` modules and is the supported path to a production runner.

Reach for this example when:

| You want to | Why this one |
|-------------|--------------|
| Skip the Packer build entirely | No pre-baked image is needed - it boots a Marketplace image |
| Pin an exact Docker / `sg-runner` version | `docker_version` and `sg_runner_version` are installed verbatim at boot |
| Reproduce a customer environment | RHEL image, Docker version and runner version are all explicit knobs |
| Read the whole bootstrap in one place | The install script is a template in this directory, not baked into an image |

The trade-off is start-up time and repeatability: every boot re-downloads and re-installs Docker
and `sg-runner`, so the VM takes minutes to become useful and a package-repo outage breaks the
boot. The quickstart bakes all of that into an image once, so its VMs come up ready.

This example is also **not** what the runner modules deploy: it has no managed identity for the
storage backend, no custom image, and its NSG opens SSH by default. Do not treat differences
between it and a real deployment as bugs in the modules.

## What gets deployed

```
  module.runner_group  ┌──────────────────────────────┐
  ────────────────────►│  StackGuardian control plane │
        │              │  • runner group              │
        │              │  • AZURE_OIDC connector      │
        │              └──────────────────────────────┘
        │              ┌──────────────────────────────┐
        └─────────────►│  Azure (storage backend)     │
                       │  • storage account + CORS    │
                       │  • "runner" blob container   │
                       │  • AAD app + SP (OIDC)       │
                       └──────────────────────────────┘

  this root module     ┌──────────────────────────────┐
  ────────────────────►│  VNet + subnet + NSG         │
                       │  public IP + NIC             │
                       │  RHEL VM (Marketplace image) │
                       │    └─ custom_data installs   │
                       │       Docker + sg-runner,    │
                       │       then registers         │
                       └──────────────────────────────┘
```

Both resource groups must already exist - this example creates neither
(`create_azure_resource_group = false` on the runner group module).

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| **OpenTofu >= 1.0** (or Terraform >= 1.4) | |
| **Azure credentials** | Via `az login` or `ARM_*` environment variables |
| **StackGuardian API key** | Org-scoped key that can create runner groups and connectors |
| **Two existing resource groups** | One for the storage backend, one for the VM and network |
| **An SSH public key** | Required - password auth is disabled on the VM |

## Quick start

```bash
tofu init
tofu plan -out=tofuplan
tofu apply tofuplan
```

A minimal `terraform.tfvars`:

```hcl
stackguardian = {
  api_key  = "sgu_xxxxxxxxxxxxxxxxxxxxx"
  org_name = "my-org"
}

runner_storage_resource_group_name = "sg-runner-storage-rg"
compute_resource_group_name        = "sg-runner-compute-rg"
azure_location                     = "westeurope"

admin_ssh_public_key      = "ssh-ed25519 AAAA..."
ssh_source_address_prefix = "203.0.113.10/32"
```

Then:

```bash
tofu output ssh_command      # ssh azureuser@<public ip>
tofu output runner_group_url # confirm the runner shows up in the console
```

Every other variable is documented in [`variables.tf`](variables.tf) with a default.

Verify the SKU you pin actually exists in your region before applying:

```bash
az vm image list --location westeurope --publisher RedHat --offer RHEL --all -o table
```

## Checking the boot

The install script logs everything it does:

```bash
sudo tail -f /var/log/sg_runner_startup.log   # install + registration
sudo tail -f /var/log/cloud-init-output.log   # full custom_data run
systemctl status docker
docker ps
```

If the VM comes up but never appears in the runner group, that log is the first place to look -
the install runs at boot, so failures show up there rather than in the Tofu output.

## Also here

[`troubleshooting.md`](troubleshooting.md) documents an ECS-agent failure mode
(agent terminally exits after a successful registration because `/var/lib/ecs/data/agent.db`
holds a stale container-instance ARN). It applies to any private runner, not just this example.

## Limitations

- **SSH is open by default** to `ssh_source_address_prefix`. Narrow it to a single address.
- **Installs at every boot.** Slower and less repeatable than a pre-baked image.
- **No managed identity.** The VM gets no storage-backend identity, so it is not a faithful
  reproduction of a supported deployment.
- **Local state.** No backend is configured.
