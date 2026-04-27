# Azure VM Scale Set — StackGuardian Private Runner

Provisions a Linux VM Scale Set whose instances boot from a custom image
(produced by `azure/packer`) and self-register with the StackGuardian
platform. The scale set is meant to be paired with `azure/autoscaler`,
which scales it in/out based on pending-job count.

## What this module creates

- `azurerm_linux_virtual_machine_scale_set` — runs the runner image
- VNet + Subnet (optional, when `network.create_network = true`)
- NSG + rules
- NAT Gateway + Public IP (optional, when `network.create_network_infrastructure = true`)

## Wiring with `azure/autoscaler`

Pass this module's outputs into the autoscaler:

```hcl
module "vmss" {
  source = "../vmss"
  # ...
}

module "autoscaler" {
  source = "../autoscaler"

  vmss = {
    name                = module.vmss.vmss_name
    resource_group_name = module.vmss.vmss_resource_group_name
  }
  # ...
}
```

## Notes

- `instances` is `ignore_changes`d after first apply so the autoscaler can drive count without Terraform fighting it.
- `upgrade_mode = "Manual"` — image/SKU changes do **not** roll existing instances; trigger an instance refresh explicitly when you ship a new image.
- SSH key generation is opt-in (`firewall.generate_ssh_key = true`) to avoid storing private keys in Terraform state by default. Prefer providing your own `firewall.ssh_public_key`.
