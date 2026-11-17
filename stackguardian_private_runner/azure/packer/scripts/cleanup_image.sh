#!/bin/sh
# Cleanup helper for the managed image produced by this Packer build.
#
# Mirrors aws/packer/scripts/cleanup_amis.sh: targets ONLY the image whose
# resource ID is passed in via TARGET_IMAGE_ID (sourced from the Terraform
# state on `terraform destroy`). Will not enumerate or delete other images.
#
# Required env:
#   TARGET_IMAGE_ID   Full Azure resource ID of the managed image to delete.
#   ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_OIDC_TOKEN_FILE_PATH
#                     Federated credentials exposed by the StackGuardian Azure connector.
# Optional env:
#   DRY_RUN=true      Print actions without executing them.

set -e

_have_az() {
  command -v az >/dev/null 2>&1
}

_login_service_principal() {
  az login --service-principal -u "$ARM_CLIENT_ID" -t "$ARM_TENANT_ID" \
    --federated-token "$(cat "$ARM_OIDC_TOKEN_FILE_PATH")" --allow-no-subscriptions >/dev/null
  az account set --subscription "$ARM_SUBSCRIPTION_ID"
}

_verify_credentials() {
  _login_service_principal
  if ! az account show >/dev/null 2>&1; then
    echo "ERROR: Azure login failed. Check ARM_CLIENT_ID / ARM_TENANT_ID / ARM_SUBSCRIPTION_ID / ARM_OIDC_TOKEN_FILE_PATH." >&2
    exit 1
  fi
}

_image_exists() {
  image_id="$1"
  az resource show --ids "$image_id" >/dev/null 2>&1
}

_delete_image() {
  image_id="$1"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo ">> [dry-run] az image delete --ids $image_id"
    return 0
  fi

  echo ">> Deleting Azure managed image: $image_id"
  if az image delete --ids "$image_id" 2>&1; then
    echo ">>   ✓ Image deleted"
  else
    echo ">>   ✗ Failed to delete image: $image_id" >&2
    return 1
  fi
}

main() {
  echo "## ----------"
  echo ">> Azure managed image cleanup"
  echo "## ----------"

  if ! _have_az; then
    echo "INFO: Azure CLI not available. Image must be cleaned up manually."
    echo ">> Install az and re-run, or remove the image via the Azure portal."
    exit 0
  fi

  _verify_credentials

  target="${TARGET_IMAGE_ID:-}"
  if [ -z "$target" ] || [ "$target" = "null" ]; then
    echo ">> No TARGET_IMAGE_ID provided - nothing to cleanup."
    exit 0
  fi

  if ! _image_exists "$target"; then
    echo ">> Image not found (already deleted?): $target"
    exit 0
  fi

  _delete_image "$target"

  echo "## ----------"
  echo ">> Cleanup complete"
  echo "## ----------"
}

main "$@"
