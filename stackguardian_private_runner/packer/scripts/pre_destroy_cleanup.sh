#!/bin/sh

set -e

trap _cleanup EXIT INT TERM

OS_ARCH=""
OS_TYPE=""

WORKING_DIR=""
TEMP_DIRS=""
CLEANUP_FILE="ami_cleanup_info.txt"

_cleanup() { #{{{
  echo "## ----------"
  echo ">> Cleaning up pre-destroy script.."

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

_detect_region() { #{{{
  region="${AWS_DEFAULT_REGION:-}"
  if [ -z "$region" ] && command -v aws >/dev/null 2>&1; then
    region=$(aws configure get region 2>/dev/null || echo "")
  fi
  echo "${region:-us-east-1}"
}
#}}}: _detect_region

_install_aws_cli() { #{{{
  os_arch="$OS_ARCH"
  os_type="$OS_TYPE"

  echo "## ----------"
  echo ">> Installing AWS CLI v2.."
  _mktemp_directory && cd "$WORKING_DIR"

  if [ "$os_type" = "linux" ]; then
    if [ "$os_arch" = "amd64" ]; then
      zip_name="awscli-exe-linux-x86_64.zip"
    elif [ "$os_arch" = "arm64" ]; then
      zip_name="awscli-exe-linux-aarch64.zip"
    else
      echo "ERROR: Unsupported architecture for AWS CLI: $os_arch"
      exit 1
    fi

    download_url="https://awscli.amazonaws.com/$zip_name"

    if _wget_wrapper "$download_url"; then
      unzip "$zip_name"
      sudo ./aws/install

      echo ">> Installed to $(which aws)."
      echo ">> Version: $(aws --version)"
    else
      echo "ERROR: Failed to download AWS CLI from: $download_url"
      exit 1
    fi
  else
    echo "ERROR: Unsupported OS for AWS CLI installation: $os_type"
    exit 1
  fi
}
#}}}: _install_aws_cli

_capture_ami_info() { #{{{
  region="$1"

  echo ">> Creating cleanup info file.."
  echo "# AMI Cleanup Information - $(date)" > "$CLEANUP_FILE"
  echo "# Generated before terraform destroy" >> "$CLEANUP_FILE"
  echo "# Use this information to manually clean up AMIs if needed" >> "$CLEANUP_FILE"
  echo "# Region: $region" >> "$CLEANUP_FILE"
  echo "" >> "$CLEANUP_FILE"

  echo ">> Searching for AMIs with pattern: SG-RUNNER-ami-*"
  if aws ec2 describe-images \
      --region "$region" \
      --owners self \
      --filters "Name=name,Values=SG-RUNNER-ami-*" \
      --query 'Images[*].[ImageId,Name,CreationDate,State]' \
      --output table >> "$CLEANUP_FILE" 2>/dev/null; then
    echo ">> AMI information captured successfully"
  else
    echo ">> No AMIs found or error accessing AWS"
  fi

  echo "" >> "$CLEANUP_FILE"
  echo "# Manual cleanup commands:" >> "$CLEANUP_FILE"
  echo "# To deregister AMIs (replace AMI_ID with actual AMI ID):" >> "$CLEANUP_FILE"
  echo "# aws ec2 deregister-image --region $region --image-id AMI_ID" >> "$CLEANUP_FILE"
  echo "" >> "$CLEANUP_FILE"
  echo "# To delete associated snapshots (get snapshot IDs from AMI details):" >> "$CLEANUP_FILE"
  echo "# aws ec2 delete-snapshot --region $region --snapshot-id SNAPSHOT_ID" >> "$CLEANUP_FILE"
  echo "" >> "$CLEANUP_FILE"
  echo "# Bulk cleanup script is available in scripts/cleanup_amis.sh" >> "$CLEANUP_FILE"

  echo ">> AMI information saved to: $CLEANUP_FILE"
}
#}}}: _capture_ami_info

main() { #{{{
  OS_ARCH="$(_detect_arch)"
  OS_TYPE="$(_detect_os)"

  echo "## ----------"
  echo ">> Pre-destroy cleanup: Capturing AMI information for manual cleanup"
  echo "## ----------"

  region="$(_detect_region)"
  echo ">> Using AWS region: $region"

  if ! command -v aws >/dev/null 2>&1; then
    echo ">> AWS CLI not found, installing.."
    _install_aws_cli
  else
    echo ">> AWS CLI found: $(aws --version)"
  fi

  _capture_ami_info "$region"

  echo "## ----------"
}
#}}}: main

main "$@"
