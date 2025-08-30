#!/bin/sh

set -e

echo "## ----------"
echo "Pre-destroy cleanup: Capturing AMI information for manual cleanup"
echo "## ----------"

# Try to detect AWS region from various sources
REGION="${AWS_DEFAULT_REGION:-}"
if [ -z "$REGION" ] && command -v aws >/dev/null 2>&1; then
    REGION=$(aws configure get region 2>/dev/null || echo "")
fi
REGION="${REGION:-us-east-1}"

# Check if AWS CLI is available
if ! command -v aws >/dev/null 2>&1; then
    echo "WARNING: AWS CLI not found. AMI information cannot be captured."
    echo "Please manually check for AMIs with name pattern: SG-RUNNER-ami-*"
    exit 0
fi

# Create cleanup info file
CLEANUP_FILE="ami_cleanup_info.txt"
echo "# AMI Cleanup Information - $(date)" > "$CLEANUP_FILE"
echo "# Generated before terraform destroy" >> "$CLEANUP_FILE"
echo "# Use this information to manually clean up AMIs if needed" >> "$CLEANUP_FILE"
echo "# Region: $REGION" >> "$CLEANUP_FILE"
echo "" >> "$CLEANUP_FILE"

# Find AMIs created by this Packer build
echo "Searching for AMIs with pattern: SG-RUNNER-ami-*"
aws ec2 describe-images \
    --region "$REGION" \
    --owners self \
    --filters "Name=name,Values=SG-RUNNER-ami-*" \
    --query 'Images[*].[ImageId,Name,CreationDate,State]' \
    --output table >> "$CLEANUP_FILE" 2>/dev/null || echo "No AMIs found or error accessing AWS"

# Add cleanup commands
echo "" >> "$CLEANUP_FILE"
echo "# Manual cleanup commands:" >> "$CLEANUP_FILE"
echo "# To deregister AMIs (replace AMI_ID with actual AMI ID):" >> "$CLEANUP_FILE"
echo "# aws ec2 deregister-image --region $REGION --image-id AMI_ID" >> "$CLEANUP_FILE"
echo "" >> "$CLEANUP_FILE"
echo "# To delete associated snapshots (get snapshot IDs from AMI details):" >> "$CLEANUP_FILE"
echo "# aws ec2 delete-snapshot --region $REGION --snapshot-id SNAPSHOT_ID" >> "$CLEANUP_FILE"
echo "" >> "$CLEANUP_FILE"
echo "# Bulk cleanup script is available in scripts/cleanup_amis.sh" >> "$CLEANUP_FILE"

echo "AMI information saved to: $CLEANUP_FILE"
echo "## ----------"