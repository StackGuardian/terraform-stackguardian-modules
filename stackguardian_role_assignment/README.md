# StackGuardian Role Assignment

Assigns one role through the provider v1.12 `roles` list. Configure the StackGuardian provider in the calling root.

```hcl
module "assignment" {
  source      = "./stackguardian_role_assignment"
  role_name   = "developer"
  subject     = "developer@example.invalid"
  entity_type = "EMAIL"
}
```

Outputs: `user`, `role`.
