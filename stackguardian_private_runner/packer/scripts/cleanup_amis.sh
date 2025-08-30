#!/bin/sh

set -e

echo "## ----------"
echo "AMI Cleanup Script - Automatic AMI deregistration and snapshot deletion"
echo "## ----------"

# Check if AWS CLI is available
if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI not found. Cannot perform automatic cleanup."
    echo "Please install AWS CLI or perform manual cleanup using the AWS Console."
    exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "ERROR: AWS credentials not configured or invalid."
    echo "Please configure AWS CLI credentials before running this script."
    exit 1
fi

# Get region from environment or default
REGION="${REGION:-us-east-1}"
echo "Using AWS region: $REGION"

# Function to deregister AMI and delete snapshots
cleanup_ami() {
    ami_id="$1"
    ami_name="$2"

    echo "Processing AMI: $ami_id ($ami_name)"

    # Get snapshot IDs before deregistering AMI
    snapshots=$(aws ec2 describe-images \
        --region "$REGION" \
        --image-ids "$ami_id" \
        --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId].Ebs.SnapshotId' \
        --output text 2>/dev/null || echo "")

    # Deregister AMI
    echo "  Deregistering AMI: $ami_id"
    if aws ec2 deregister-image --region "$REGION" --image-id "$ami_id" 2>/dev/null; then
        echo "  ✓ AMI deregistered successfully"

        # Delete associated snapshots
        if [ -n "$snapshots" ] && [ "$snapshots" != "None" ]; then
            for snapshot_id in $snapshots; do
                echo "  Deleting snapshot: $snapshot_id"
                if aws ec2 delete-snapshot --region "$REGION" --snapshot-id "$snapshot_id" 2>/dev/null; then
                    echo "  ✓ Snapshot deleted successfully"
                else
                    echo "  ✗ Failed to delete snapshot: $snapshot_id"
                fi
            done
        else
            echo "  No snapshots found for this AMI"
        fi
    else
        echo "  ✗ Failed to deregister AMI: $ami_id"
    fi

    echo ""
}

# Find all SG-RUNNER AMIs
echo "Searching for AMIs with pattern: SG-RUNNER-ami-*"
amis=$(aws ec2 describe-images \
    --region "$REGION" \
    --owners self \
    --filters "Name=name,Values=SG-RUNNER-ami-*" \
    --query 'Images[*].[ImageId,Name]' \
    --output text 2>/dev/null || echo "")

if [ -z "$amis" ] || [ "$amis" = "None" ]; then
    echo "No SG-RUNNER AMIs found in region $REGION"
    exit 0
fi

echo "Found AMIs:"
echo "$amis" | while read -r ami_id ami_name; do
    echo "  $ami_id - $ami_name"
done
echo ""

# Check if running in automated mode (terraform destroy)
if [ "${TERRAFORM_DESTROY:-}" = "true" ]; then
    echo "Running in automated mode - cleaning up all SG-RUNNER AMIs"
    echo "$amis" | while read -r ami_id ami_name; do
        cleanup_ami "$ami_id" "$ami_name"
    done
else
    # Interactive mode
    echo "Interactive mode - you can choose which AMIs to clean up"
    echo "Do you want to proceed with cleanup of ALL listed AMIs? (y/N)"
    read -r confirm

    case "$confirm" in
        [Yy]|[Yy][Ee][Ss])
            echo "Proceeding with cleanup..."
            echo "$amis" | while read -r ami_id ami_name; do
                cleanup_ami "$ami_id" "$ami_name"
            done
            ;;
        *)
            echo "Cleanup cancelled. Use the following commands for manual cleanup:"
            echo ""
            echo "$amis" | while read -r ami_id ami_name; do
                echo "# For AMI: $ami_name"
                echo "aws ec2 deregister-image --region $REGION --image-id $ami_id"
                echo "# Get snapshots: aws ec2 describe-images --region $REGION --image-ids $ami_id --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId].Ebs.SnapshotId' --output text"
                echo ""
            done
            exit 0
            ;;
    esac
fi

echo "## ----------"
echo "AMI cleanup completed"
echo "## ----------"
