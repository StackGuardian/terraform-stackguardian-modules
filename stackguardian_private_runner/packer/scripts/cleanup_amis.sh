#!/bin/sh

set -e

_detect_region() { #{{{
  region="${REGION:-}"
  if [ -z "$region" ]; then
    region="${AWS_DEFAULT_REGION:-}"
  fi
  if [ -z "$region" ] && command -v aws >/dev/null 2>&1; then
    region=$(aws configure get region 2>/dev/null || echo "")
  fi
  echo "${region:-us-east-1}"
}
#}}}: _detect_region

_verify_aws_cli() { #{{{
  if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI not found. Cannot perform automatic cleanup."
    echo "Please install AWS CLI or perform manual cleanup using the AWS Console."
    exit 1
  fi
}
#}}}: _verify_aws_cli

_verify_aws_credentials() { #{{{
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
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
  protection_status=$(aws ec2 describe-image-attribute \
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
  if aws ec2 disable-image-deregistration-protection --region "$region" --image-id "$ami_id" 2>/dev/null; then
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
  ami_name=$(aws ec2 describe-images \
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
    snapshots=$(aws ec2 describe-images \
        --region "$region" \
        --image-ids "$ami_id" \
        --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId].Ebs.SnapshotId' \
        --output text 2>/dev/null || echo "")
  fi

  echo ">>   Deregistering AMI: $ami_id"
  if aws ec2 deregister-image --region "$region" --image-id "$ami_id" 2>/dev/null; then
    echo ">>   ✓ AMI deregistered successfully"

    if [ "$delete_snapshots_flag" = "true" ]; then
      if [ -n "$snapshots" ] && [ "$snapshots" != "None" ]; then
        for snapshot_id in $snapshots; do
          echo ">>   Deleting snapshot: $snapshot_id"
          if aws ec2 delete-snapshot --region "$region" --snapshot-id "$snapshot_id" 2>/dev/null; then
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

  _verify_aws_cli
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
