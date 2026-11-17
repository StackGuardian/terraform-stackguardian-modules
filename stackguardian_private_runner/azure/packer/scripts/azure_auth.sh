#!/bin/sh
# Normalizes Azure service principal credentials into ARM_* variables.
# Sourced by build.sh and cleanup_image.sh.
#
# Accepts the azurerm provider's ARM_* names, falling back to the AZURE_* names
# used by Azure workload identity. The federated (OIDC) token is read from
# ARM_OIDC_TOKEN, or from the file in ARM_OIDC_TOKEN_FILE_PATH or
# AZURE_FEDERATED_TOKEN_FILE.

ARM_CLIENT_ID="${ARM_CLIENT_ID:-${AZURE_CLIENT_ID:-}}"
ARM_TENANT_ID="${ARM_TENANT_ID:-${AZURE_TENANT_ID:-}}"
ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID:-${AZURE_SUBSCRIPTION_ID:-}}"
ARM_CLIENT_SECRET="${ARM_CLIENT_SECRET:-${AZURE_CLIENT_SECRET:-}}"

if [ -z "${ARM_OIDC_TOKEN:-}" ]; then
  for token_file in "${ARM_OIDC_TOKEN_FILE_PATH:-}" "${AZURE_FEDERATED_TOKEN_FILE:-}"; do
    if [ -n "$token_file" ] && [ -r "$token_file" ]; then
      ARM_OIDC_TOKEN=$(cat "$token_file")
      break
    fi
  done
fi

export ARM_CLIENT_ID ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_SECRET ARM_OIDC_TOKEN

if [ -n "$ARM_CLIENT_ID" ] && [ -n "$ARM_CLIENT_SECRET" ]; then
  echo ">> Azure auth: service principal (client secret)"
elif [ -n "$ARM_CLIENT_ID" ] && [ -n "${ARM_OIDC_TOKEN:-}" ]; then
  echo ">> Azure auth: service principal (federated OIDC token)"
else
  echo ">> Azure auth: Azure CLI (az login)"
fi
