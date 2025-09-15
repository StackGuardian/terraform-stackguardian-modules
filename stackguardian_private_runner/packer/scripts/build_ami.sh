#!/bin/sh

set -e

trap _cleanup EXIT INT TERM

PACKER_EXECUTABLE=""
WORKING_DIR=""
TEMP_DIRS=""

_cleanup() { #{{{
  echo "## ----------"
  echo "Cleaning up Packer build.."

  if [ -n "$TEMP_DIRS" ]; then
    for temp_dir in $TEMP_DIRS; do
      if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
        echo "Removed temporary directory: $temp_dir"
      fi
    done
  fi

  if [ -d "$WORKING_DIR" ]; then
    rm -rf "$WORKING_DIR"
    echo "Removed temporary directory: $WORKING_DIR"
  fi
  echo "## ----------"
}
#}}}: _cleanup

_detect_arch() { #{{{
  machine="$(uname -m)"

  case "$machine" in
    x86_64) echo "amd64" ;;
    aarch64) echo "arm64" ;;
    armv7l) echo "arm" ;;
    i386|i686) echo "386" ;;
    *) echo "$machine" ;;
  esac
}
#}}}: _detect_arch

_detect_os() { #{{{
    uname -s | tr '[:upper:]' '[:lower:]'
}
#}}}: _detect_os

_wget_wrapper() { #{{{
  url="$1"
  output_file="${2:-"${url##*/}"}"

  echo ">> Downloading ${url}.."
  wget -q "$url" -O "$output_file"
  echo ">> Saved to ${output_file}."
}
#}}}: _wget_wrapper

_mktemp_directory() { #{{{
  WORKING_DIR="$(mktemp -d)"
  if [ -n "$TEMP_DIRS" ]; then
    TEMP_DIRS="$TEMP_DIRS $WORKING_DIR"
  else
    TEMP_DIRS="$WORKING_DIR"
  fi
}
#}}}: _mktemp_directory

_download_packer() { #{{{
  version="$PACKER_VERSION"
  root_dir="$(pwd)"

  os_arch="$(_detect_arch)"
  os_type="$(_detect_os)"
  zip_name="packer_${version}_${os_type}_${os_arch}.zip"
  base_url="https://releases.hashicorp.com/packer/${version}"

  download_url="${base_url}/${zip_name}"

  echo "## ----------"
  echo ">> Downloading Packer v${version}.."
  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$download_url"; then
    unzip "$zip_name"
    PACKER_EXECUTABLE="$(realpath packer)"
    cd "$root_dir"

    echo ">> Downloaded to ${PACKER_EXECUTABLE}."
    echo "## ----------"
  else
    echo "ERROR: Failed to download from: $download_url"
    exit 1
  fi
}
#}}}: _download_packer

main() { #{{{
  _download_packer

  $PACKER_EXECUTABLE init ./ami.pkr.hcl
  $PACKER_EXECUTABLE build \
    -var "base_ami=$BASE_AMI" \
    -var "os_family=$OS_FAMILY" \
    -var "os_version=$OS_VERSION" \
    -var "update_os_before_install=$UPDATE_OS" \
    -var "region=$REGION" \
    -var "ssh_username=$SSH_USERNAME" \
    -var "public_subnet_id=$PUBLIC_SUBNET_ID" \
    -var "private_subnet_id=$PRIVATE_SUBNET_ID" \
    -var "proxy_url=$PROXY_URL" \
    -var "terraform_version=$TERRAFORM_VERSION" \
    -var "terraform_versions=$TERRAFORM_VERSIONS" \
    -var "opentofu_version=$OPENTOFU_VERSION" \
    -var "opentofu_versions=$OPENTOFU_VERSIONS" \
    -var "user_script=$USER_SCRIPT" \
    -var "vpc_id=$VPC_ID" \
    -var "deregistration_protection_enabled=$DEREGISTRATION_PROTECTION_ENABLED" \
    -var "deregistration_protection_with_cooldown=$DEREGISTRATION_PROTECTION_WITH_COOLDOWN" \
    -machine-readable \
    ./ami.pkr.hcl | tee packer_manifest.log
}
#}}}: main

main "$@"
