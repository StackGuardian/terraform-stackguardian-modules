#!/usr/bin/env bash

set -o pipefail

trap _cleanup EXIT SIGINT SIGTERM ERR

declare PACKER_EXECUTABLE
declare WORKING_DIR
declare -a TEMP_DIRS

_cleanup() { #{{{
  echo "Cleaning up.."

  for temp_dir in "${TEMP_DIRS[@]}"; do
    if [[ -d "$temp_dir" ]]; then
      rm -rf "$temp_dir"
      echo "Removed temporary directory: $temp_dir"
    fi
  done

  if [[ -d "$WORKING_DIR" ]]; then
    rm -rf "$WORKING_DIR"
    echo "Removed temporary directory: $WORKING_DIR"
  fi
}
#}}}: _cleanup

_detect_arch() { #{{{
  local machine="$(uname -m)"

  declare -A arch_map=(
    ["x86_64"]="amd64"
    ["aarch64"]="arm64"
    ["armv7l"]="arm"
    ["i386"]="386"
    ["i686"]="386"
  )

  echo "${arch_map[$machine]:-$machine}"
}
#}}}: _detect_arch

_detect_os() { #{{{
    uname -s | tr '[:upper:]' '[:lower:]'
}
#}}}: _detect_os

_wget_wrapper() { #{{{
  local url="$1"
  local output_file="${2:-"${url##*/}"}"

  echo "Downloading ${url}.."
  wget -q "$url" -O "$output_file"
  echo "Saved to ${output_file}."
}
#}}}: _wget_wrapper

_mktemp_directory() { #{{{
  # local -n ref="$1"
  # ref="$(mktemp -d)"

  WORKING_DIR="$(mktemp -d)"
  TEMP_DIRS+=("$WORKING_DIR")
}
#}}}: _mktemp_directory

_download_packer() { #{{{
  local version="$PACKER_VERSION"
  local root_dir="$(pwd)"

  local os_arch="$(_detect_arch)"
  local os_type="$(_detect_os)"
  local zip_name="packer_${version}_${os_type}_${os_arch}.zip"
  local base_url="https://releases.hashicorp.com/packer/${version}"

  local download_url="${base_url}/${zip_name}"

  echo "Downloading Packer v${version}.."
  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$download_url"; then
    unzip "$zip_name"
    PACKER_EXECUTABLE="$(realpath packer)"
    cd "$root_dir"

    echo "Downloaded to ${PACKER_EXECUTABLE}."
  else
    echo "Failed to download from: $download_url"
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
    -var "region=$REGION" \
    -var "ssh_username=$SSH_USERNAME" \
    -var "subnet_id="$SUBNET_ID \
    -var "terraform_version=$TERRAFORM_VERSION" \
    -var "user_script=$USER_SCRIPT" \
    -var "vpc_id="$VPC_ID \
    -machine-readable \
    ./ami.pkr.hcl | tee packer_manifest.log
}
#}}}: main

main "$@"
