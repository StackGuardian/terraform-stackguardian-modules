#!/bin/sh
set -e
"$1" import -var-file environments/sg.tfvars 'module.policy_assignment["asc_default"].azurerm_policy_assignment.this' '/subscriptions/618c8e34-b87b-44e8-bb3a-b2de95df60ed/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn'
