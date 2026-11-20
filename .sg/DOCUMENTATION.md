# Documentation: test-terraform-cli

## 1. Overview

This stack manages one Azure resource: a **subscription-scoped Azure Policy assignment** (`SecurityCenterBuiltIn`), the default Microsoft Defender for Cloud (ASC Default) policy set on subscription `618c8e34-b87b-44e8-bb3a-b2de95df60ed`.

The workflow was:

1. Code was generated from discovered cloud resources (`azurerm_policy_assignment`, ID `SecurityCenterBuiltIn`).
2. The existing resource was imported into Terraform state via `imports.sh`.
3. The configuration was reconciled until `plan` reported no changes.

Final reconciliation result: **No changes. Your infrastructure matches the configuration.**

## 2. Resources

| Terraform address | Provider type | Real-world name / ID | Purpose |
|---|---|---|---|
| `module.policy_assignment["asc_default"].azurerm_policy_assignment.this` | `azurerm_policy_assignment` | Name `SecurityCenterBuiltIn`; ID `/subscriptions/618c8e34-b87b-44e8-bb3a-b2de95df60ed/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn` | Assigns the Azure built-in policy set `1f3afdf9-d0c9-4c3d-847f-89da613e70a8` (ASC Default, audit policies) to the subscription. |

Only one resource exists in the root configuration. The `policy_assignment` module is instantiated once, with `for_each` key `asc_default`.

## 3. Module structure

### Root (`./`)

- `main.tf`: one `module "policy_assignment"` block using `for_each = var.policy_assignments` and passing `name`, `scope`, `policy_definition_id`, `description`, `display_name` from each map entry.
- `variables.tf`: declares `policy_assignments` (a `map(object)`, default `{}`).
- `outputs.tf`: present but empty. No outputs are exported.
- `versions.tf`: requires provider `hashicorp/azurerm` `~> 2.99`.
- `providers.tf`: configures `azurerm` with `skip_provider_registration = true` and an empty `features {}` block.

### `modules/policy_assignment/`

- `main.tf`: a single `azurerm_policy_assignment` resource named `this`, with arguments taken directly from the module variables.
- `variables.tf`: `name`, `scope`, `policy_definition_id` (required strings); `description`, `display_name` (optional strings, default `null`).
- `outputs.tf`: output `id` = `azurerm_policy_assignment.this.id`.

### External modules

No external (`git::`) modules are called from the root configuration. The discovery metadata lists a `test-terraform-cli` module (`git::https://github.com/StackGuardian/test-terraform-cli.git?ref=main`) that covers `null_resource`. The root code does not reference it, and no `null_resource` exists in this stack. It is not used and is documented here only for completeness.

## 4. How import works

`imports.sh` runs one import command:

```sh
"$1" import -var-file environments/sg.tfvars \
  'module.policy_assignment["asc_default"].azurerm_policy_assignment.this' \
  '/subscriptions/618c8e34-b87b-44e8-bb3a-b2de95df60ed/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn'
```

- `$1` is the IaC binary path (for example, `tofu`). The script takes it as an argument.
- The first argument after `import` is the module-qualified Terraform address. The second is the Azure ARM resource ID. Use the full ARM ID, not the short name.
- The script was run once to populate state. It does not need to run again while state is intact.

**To re-import the resource if state is lost** (after `init`, with the same variables in place):

```sh
tofu import -var-file=environments/sg.tfvars \
  'module.policy_assignment["asc_default"].azurerm_policy_assignment.this' \
  '/subscriptions/618c8e34-b87b-44e8-bb3a-b2de95df60ed/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn'
```

Then run `plan` to confirm no changes.

## 5. How to use the code

Run these commands from the working directory. Replace `tofu` with your binary path if needed.

```sh
# 1. Initialise providers and modules
tofu init

# 2. Preview changes using the shipped variable values
tofu plan -var-file=environments/sg.tfvars

# 3. Apply changes
tofu apply -var-file=environments/sg.tfvars
```

### Targeting another environment (for example, dev → prod)

No `.tf` edits are required:

1. Copy `environments/sg.tfvars` to a new file, for example `environments/prod.tfvars`.
2. Edit the values in the copy. The key fields are `policy_assignments.<key>.name`, `scope` (subscription ID), `policy_definition_id`, `description`, and `display_name`. The map key (for example, `asc_default`) becomes the `for_each` key in the state address.
3. Plan against the new file:

   ```sh
   tofu plan -var-file=environments/prod.tfvars
   ```

4. Note that the import in `imports.sh` targets the `asc_default` address and the `sg` subscription ID. For a different environment, the existing state is not reused. Import the target resource with the matching address and ARM ID before planning, or the plan will propose creating a new assignment.

## 6. Variables

| Variable | Type | Controls | Sensitive? |
|---|---|---|---|
| `policy_assignments` | `map(object({ name, scope, policy_definition_id, description?, display_name? }))` | The set of policy assignments to create. Each map key becomes a `for_each` instance (`module.policy_assignment["<key>"]`). | No |

Fields of each entry:

- `name`: the policy assignment name in Azure (`SecurityCenterBuiltIn`).
- `scope`: the ARM scope to assign to (`/subscriptions/618c8e34-…`).
- `policy_definition_id`: the policy or policy set definition ID (`/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-…`).
- `description`: optional text. Set in `sg.tfvars`.
- `display_name`: optional label. Set in `sg.tfvars`.

**Secrets:** no variable in this configuration is marked `sensitive`. The shipped `environments/sg.tfvars` contains no secret values, and no `secrets.auto.tfvars` is required. If you add a sensitive variable later, provide its value in a `secrets.auto.tfvars` file or with `-var` before planning. Do not commit that file.

## 7. Infrastructure graph

```
subscription 618c8e34-b87b-44e8-bb3a-b2de95df60ed   (scope, not managed by this stack)
└── policySetDefinitions/1f3afdf9-…  (policy_definition_id, referenced, not managed)
    ▲
    │ referenced by
    │
module.policy_assignment["asc_default"]  (module.policy_assignment, for_each key "asc_default")
└── azurerm_policy_assignment.this  (name "SecurityCenterBuiltIn", scope = subscription)
```

There are no dependencies between managed resources. The only reference is that the assignment points at the subscription scope and at the policy set definition. Both of these are external to the stack.

## 8. Notable decisions & caveats

- **Provider version pinned to `~> 2.99`.** The `azurerm_policy_assignment` resource was removed in azurerm 3.0 and later. Do not upgrade the provider without rewriting this resource.
- **`skip_provider_registration = true`** is set in `providers.tf`. Automatic resource-provider registration returned HTTP 403 during discovery, so it is disabled.
- **Import ID format.** The import uses the full ARM resource ID, not the short name `SecurityCenterBuiltIn`.
- **Module wrapping.** The single resource is wrapped in `modules/policy_assignment` and called with `for_each` over `var.policy_assignments`. This keeps the stack extensible to more assignments, at the cost of longer state addresses.
- **Empty root outputs.** `outputs.tf` is empty. The module's `id` output is not surfaced at the root.
- **No `lifecycle { ignore_changes }` blocks.** Every attribute is managed. Any attribute changed out-of-band will show up as drift in `plan`.
- **Omitted computed attributes.** Only configurable arguments are declared. Read-only attributes (for example, the assignment `identity` and `location` when not set) are not modelled. Azure may return values for them that are not reflected in code.
- **Descriptive text is copied from Azure.** The `description` value in `sg.tfvars` is the default ASC text as returned by Azure, including the URL. Editing it in code causes an in-place update.
- **Local state file present.** `terraform.tfstate` is in the working directory. Treat it as sensitive and keep it out of version control unless you use a remote backend.
- **Stale discovery metadata.** The module index in the discovery data lists an unrelated `null_resource` module. It is not used by this stack (see section 3).
- **Current drift:** none. The final reconciliation reported no changes.
