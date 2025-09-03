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

_cleanup_ami() { #{{{
  ami_id="$1"
  ami_name="$2"
  region="$3"

  echo ">> Processing AMI: $ami_id ($ami_name)"

  snapshots=$(aws ec2 describe-images \
      --region "$region" \
      --image-ids "$ami_id" \
      --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId].Ebs.SnapshotId' \
      --output text 2>/dev/null || echo "")

  echo ">>   Deregistering AMI: $ami_id"
  if aws ec2 deregister-image --region "$region" --image-id "$ami_id" 2>/dev/null; then
    echo ">>   ✓ AMI deregistered successfully"

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
    echo ">>   ✗ Failed to deregister AMI: $ami_id"
  fi

  echo ""
}
#}}}: _cleanup_ami

_list_amis() { #{{{
  region="$1"

  echo ">> Searching for AMIs with pattern: SG-RUNNER-ami-*"
  aws ec2 describe-images \
    --region "$region" \
    --owners self \
    --filters "Name=name,Values=SG-RUNNER-ami-*" \
    --query 'Images[*].[ImageId,Name]' \
    --output text 2>/dev/null || echo ""
}
#}}}: _list_amis

_print_ami_list() { #{{{
  amis="$1"

  echo ">> Found AMIs:"
  echo "$amis" | while read -r ami_id ami_name; do
    echo ">>   $ami_id - $ami_name"
  done
  echo ""
}
#}}}: _print_ami_list

_cleanup_all_amis() { #{{{
  amis="$1"
  region="$2"

  echo "$amis" | while read -r ami_id ami_name; do
    _cleanup_ami "$ami_id" "$ami_name" "$region"
  done
}
#}}}: _cleanup_all_amis

_interactive_cleanup() { #{{{
  amis="$1"
  region="$2"

  echo ">> Interactive mode - you can choose which AMIs to clean up"
  echo ">> Do you want to proceed with cleanup of ALL listed AMIs? (y/N)"
  read -r confirm

  case "$confirm" in
    [Yy]|[Yy][Ee][Ss])
      echo ">> Proceeding with cleanup.."
      _cleanup_all_amis "$amis" "$region"
      ;;
    *)
      echo ">> Cleanup cancelled. Use the following commands for manual cleanup:"
      echo ""
      echo "$amis" | while read -r ami_id ami_name; do
        echo "# For AMI: $ami_name"
        echo "aws ec2 deregister-image --region $region --image-id $ami_id"
        echo "# Get snapshots: aws ec2 describe-images --region $region --image-ids $ami_id --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId].Ebs.SnapshotId' --output text"
        echo ""
      done
      exit 0
      ;;
  esac
}
#}}}: _interactive_cleanup

main() { #{{{
  echo "## ----------"
  echo ">> AMI Cleanup Script - Automatic AMI deregistration and snapshot deletion"
  echo "## ----------"

  _verify_aws_cli
  _verify_aws_credentials

  region="$(_detect_region)"
  echo ">> Using AWS region: $region"

  amis="$(_list_amis "$region")"

  if [ -z "$amis" ] || [ "$amis" = "None" ]; then
    echo ">> No SG-RUNNER AMIs found in region $region"
    exit 0
  fi

  _print_ami_list "$amis"

  if [ "${TERRAFORM_DESTROY:-}" = "true" ]; then
    echo ">> Running in automated mode - cleaning up all SG-RUNNER AMIs"
    _cleanup_all_amis "$amis" "$region"
  else
    _interactive_cleanup "$amis" "$region"
  fi

  echo "## ----------"
  echo ">> AMI cleanup completed"
  echo "## ----------"
}
#}}}: main

main "$@"
