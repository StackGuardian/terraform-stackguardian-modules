#!/bin/sh

set -e

AWS_EXECUTABLE=""
WORKING_DIR=""

_detect_arch() { #{{{
  machine="$(uname -m)"

  case "$machine" in
    x86_64) echo "x86_64" ;;
    aarch64) echo "aarch64" ;;
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
}
#}}}: _mktemp_directory

_download_aws_cli() { #{{{
  # First check if AWS CLI is already available on the system
  if command -v aws >/dev/null 2>&1; then
    AWS_EXECUTABLE="$(command -v aws)"
    echo "## ----------"
    echo ">> Using system AWS CLI: $AWS_EXECUTABLE"
    if $AWS_EXECUTABLE --version 2>&1; then
      echo ">> AWS CLI is available and working"
    else
      echo ">> WARNING: AWS CLI found but version check failed"
    fi
    echo "## ----------"
    return 0
  fi

  root_dir="$(pwd)"
  os_arch="$(_detect_arch)"
  os_type="$(_detect_os)"

  # Only support Linux
  if [ "$os_type" != "linux" ]; then
    echo "ERROR: Unsupported operating system: $os_type"
    echo ">> AWS CLI v2 automatic installation is only supported on Linux"
    echo ">> Please install AWS CLI manually: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
  fi

  echo "## ----------"
  echo ">> AWS CLI not found on system, downloading AWS CLI v2 for ${os_type} (${os_arch}).."

  zip_name="awscliv2.zip"
  download_url="https://awscli.amazonaws.com/awscli-exe-${os_type}-${os_arch}.zip"

  _mktemp_directory && cd "$WORKING_DIR"

  if _wget_wrapper "$download_url" "$zip_name"; then
    echo ">> Extracting AWS CLI.."
    unzip -q "$zip_name"

    echo ">> Installing AWS CLI v2 to temporary directory.."
    # Install to temp directory - installer may fail during version check but still create files
    ./aws/install -i "$WORKING_DIR/aws-cli" -b "$WORKING_DIR/bin" 2>&1 || true

    cd "$root_dir"

    # Use the wrapper symlink created by installer - it handles all path resolution
    AWS_EXECUTABLE="$WORKING_DIR/bin/aws"

    if [ -f "$AWS_EXECUTABLE" ]; then
      echo ">> AWS CLI v2 installed: $AWS_EXECUTABLE"
      # Test if it actually works
      if $AWS_EXECUTABLE --version >/dev/null 2>&1; then
        echo ">> AWS CLI v2 is working"
        echo "## ----------"
        return 0
      else
        echo ">> AWS CLI v2 binary exists but cannot execute (missing system libraries)"
        echo ">> Falling back to AWS CLI v1 via pip..."
      fi
    else
      echo ">> AWS CLI v2 installation failed, falling back to pip installation..."
    fi

    # Fallback to AWS CLI v1 via pip (more portable)
    if command -v pip3 >/dev/null 2>&1; then
      echo ">> Installing AWS CLI v1 via pip3..."
      pip3 install --user awscli >/dev/null 2>&1 || pip3 install --user awscli
      AWS_EXECUTABLE="$HOME/.local/bin/aws"

      if [ -f "$AWS_EXECUTABLE" ] && $AWS_EXECUTABLE --version >/dev/null 2>&1; then
        echo ">> AWS CLI v1 installed successfully via pip3"
        echo "## ----------"
        return 0
      fi
    elif command -v pip >/dev/null 2>&1; then
      echo ">> Installing AWS CLI v1 via pip..."
      pip install --user awscli >/dev/null 2>&1 || pip install --user awscli
      AWS_EXECUTABLE="$HOME/.local/bin/aws"

      if [ -f "$AWS_EXECUTABLE" ] && $AWS_EXECUTABLE --version >/dev/null 2>&1; then
        echo ">> AWS CLI v1 installed successfully via pip"
        echo "## ----------"
        return 0
      fi
    fi

    echo "ERROR: Failed to install AWS CLI (tried v2 and v1 via pip)"
    echo ">> Please install AWS CLI manually or ensure glibc is available"
    exit 1

  else
    echo "ERROR: Failed to download AWS CLI from: $download_url"
    exit 1
  fi
}
#}}}: _download_aws_cli

_detect_region() { #{{{
  region="${REGION:-}"
  if [ -z "$region" ]; then
    region="${AWS_DEFAULT_REGION:-}"
  fi
  if [ -z "$region" ] && [ -n "$AWS_EXECUTABLE" ]; then
    region=$($AWS_EXECUTABLE configure get region 2>/dev/null || echo "")
  fi
  echo "${region:-us-east-1}"
}
#}}}: _detect_region

_verify_aws_cli() { #{{{
  if [ -z "$AWS_EXECUTABLE" ] || [ ! -x "$AWS_EXECUTABLE" ]; then
    return 1
  fi
  return 0
}
#}}}: _verify_aws_cli

_verify_aws_credentials() { #{{{
  if ! $AWS_EXECUTABLE sts get-caller-identity >/dev/null 2>&1; then
    echo "ERROR: AWS credentials not configured or invalid."
    echo "Please configure AWS CLI credentials before running this script."
    exit 1
  fi
}
#}}}: _verify_aws_credentials

_check_ami_protection() { #{{{
  ami_id="$1"
  region="$2"

  echo ">> Checking deregistration protection for AMI: $ami_id"
  protection_status=$($AWS_EXECUTABLE ec2 describe-image-attribute \
    --region "$region" \
    --image-id "$ami_id" \
    --attribute deregistrationProtection \
    --query 'DeregistrationProtection.Value' \
    --output text 2>/dev/null || echo "false")

  echo "$protection_status"
}
#}}}: _check_ami_protection

_disable_ami_protection() { #{{{
  ami_id="$1"
  region="$2"

  echo ">> Disabling deregistration protection for AMI: $ami_id"
  if $AWS_EXECUTABLE ec2 disable-image-deregistration-protection --region "$region" --image-id "$ami_id" 2>/dev/null; then
    echo ">>   ✓ Deregistration protection disabled"
    return 0
  else
    echo ">>   ✗ Failed to disable deregistration protection"
    return 1
  fi
}
#}}}: _disable_ami_protection

_cleanup_target_ami() { #{{{
  ami_id="$1"
  region="$2"

  if [ -z "$ami_id" ] || [ "$ami_id" = "null" ]; then
    echo ">> No target AMI specified - skipping cleanup"
    return 0
  fi

  # Get AMI name for display
  ami_name=$($AWS_EXECUTABLE ec2 describe-images \
    --region "$region" \
    --image-ids "$ami_id" \
    --query 'Images[0].Name' \
    --output text 2>/dev/null || echo "Unknown")

  if [ "$ami_name" = "None" ] || [ "$ami_name" = "Unknown" ]; then
    echo ">> AMI $ami_id not found or inaccessible - skipping cleanup"
    return 0
  fi

  _cleanup_ami "$ami_id" "$ami_name" "$region"
}
#}}}: _cleanup_target_ami

_cleanup_ami() { #{{{
  ami_id="$1"
  ami_name="$2"
  region="$3"

  echo ">> Processing AMI: $ami_id ($ami_name)"

  # Check deregistration protection status
  protection_enabled=$(_check_ami_protection "$ami_id" "$region")

  if [ "$protection_enabled" != "disabled" ]; then
    echo ">>   ⚠️  AMI has deregistration protection enabled"
    echo ">>   🚨 Automatic cleanup enabled - attempting to disable protection"

    if ! _disable_ami_protection "$ami_id" "$region"; then
      echo ">>   ✗ Cannot proceed with cleanup - protection disable failed"
      return 1
    fi

    # Check for cooldown period
    if [ "$protection_enabled" = "enabled-with-cooldown" ]; then
      echo ">>   ⏰ WARNING: AMI was configured with 24-hour cooldown period"
      echo ">>   📅 You may need to wait up to 24 hours before deregistration completes"
      echo ">>   💡 Manual cleanup commands (run after cooldown expires):"
      echo ">>      aws ec2 deregister-image --region $region --image-id $ami_id"
      if [ "${DELETE_SNAPSHOTS:-true}" = "true" ]; then
        echo ">>      # After deregistration, cleanup snapshots:"
        echo ">>      aws ec2 describe-images --region $region --image-ids $ami_id --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId].Ebs.SnapshotId' --output text | xargs -n1 aws ec2 delete-snapshot --region $region --snapshot-id"
      fi
      return 0
    fi
  fi

  delete_snapshots_flag="${DELETE_SNAPSHOTS:-true}"

  if [ "$delete_snapshots_flag" = "true" ]; then
    snapshots=$($AWS_EXECUTABLE ec2 describe-images \
        --region "$region" \
        --image-ids "$ami_id" \
        --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId].Ebs.SnapshotId' \
        --output text 2>/dev/null || echo "")
  fi

  echo ">>   Deregistering AMI: $ami_id"
  if $AWS_EXECUTABLE ec2 deregister-image --region "$region" --image-id "$ami_id" 2>/dev/null; then
    echo ">>   ✓ AMI deregistered successfully"

    if [ "$delete_snapshots_flag" = "true" ]; then
      if [ -n "$snapshots" ] && [ "$snapshots" != "None" ]; then
        for snapshot_id in $snapshots; do
          echo ">>   Deleting snapshot: $snapshot_id"
          if $AWS_EXECUTABLE ec2 delete-snapshot --region "$region" --snapshot-id "$snapshot_id" 2>/dev/null; then
            echo ">>   ✓ Snapshot deleted successfully"
          else
            echo ">>   ✗ Failed to delete snapshot: $snapshot_id"
          fi
        done
      else
        echo ">>   No snapshots found for this AMI"
      fi
    else
      echo ">>   Skipping snapshot deletion (delete_snapshots=false)"
    fi
  else
    echo ">>   ✗ Failed to deregister AMI: $ami_id"
    if [ "$protection_enabled" = "enabled-with-cooldown" ]; then
      echo ">>   💡 This may be due to the 24-hour cooldown period being active"
      echo ">>   📅 Please retry this command after the cooldown expires"
    fi
  fi

  echo ""
}
#}}}: _cleanup_ami


main() { #{{{
  echo "## ----------"
  echo ">> AMI Cleanup Script - Automatic AMI deregistration and snapshot deletion"
  echo "## ----------"

  # Download/cache AWS CLI v2 if not already available
  _download_aws_cli

  if ! _verify_aws_cli; then
    echo "INFO: AWS CLI not found. AMI should be cleaned up manually."
    echo ">> Please use AWS Console or install AWS CLI to clean up the AMI."
    exit 0
  fi

  _verify_aws_credentials

  region="$(_detect_region)"
  echo ">> Using AWS region: $region"

  target_ami="${TARGET_AMI_ID:-}"

  echo ">> 🚨 Automatic cleanup enabled - will bypass AMI protection (except cooldown)"

  # Only cleanup the specific AMI from terraform state
  if [ -n "$target_ami" ] && [ "$target_ami" != "null" ]; then
    echo ">> Target AMI specified: $target_ami"
    _cleanup_target_ami "$target_ami" "$region"
  else
    echo ">> No target AMI specified - nothing to cleanup"
    echo ">> This script only cleans up the AMI created by this Terraform configuration"
    exit 0
  fi

  echo "## ----------"
  echo ">> AMI cleanup completed"
  echo "## ----------"
}
#}}}: main

main "$@"
