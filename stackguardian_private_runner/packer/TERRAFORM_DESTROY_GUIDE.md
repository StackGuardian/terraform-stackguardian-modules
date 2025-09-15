# Terraform Destroy Guide for Packer AMI Builder

This guide explains how to properly handle `terraform destroy` for the Packer-based AMI building setup.

## Important Notes

⚠️ **AMI Persistence**: AMIs created by Packer will **NOT** be automatically destroyed when running `terraform destroy`. They persist in your AWS account and may incur storage costs.

⚠️ **Deregistration Protection**: AMIs are created with deregistration protection enabled to prevent accidental deletion.

## Before Running `terraform destroy`

1. **Capture AMI Information**: The pre-destroy script will automatically create `ami_cleanup_info.txt` with details of created AMIs.

2. **Backup State**: Consider backing up your Terraform state:
   ```bash
   cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
   ```

## Running `terraform destroy`

```bash
terraform destroy
```

The destroy process will:

- Trigger the pre-destroy cleanup script
- Generate `ami_cleanup_info.txt` with AMI details
- Remove Terraform-managed resources
- Leave AMIs intact for manual cleanup

## Post-Destroy Manual Cleanup

### Option 1: Use the Automated Cleanup Script

```bash
./scripts/cleanup_amis.sh
```

This script will:

- List all SG-RUNNER AMIs
- Optionally deregister selected AMIs
- Delete associated EBS snapshots

### Option 2: Manual AWS CLI Cleanup

1. **List AMIs**:

   ```bash
   aws ec2 describe-images \
     --region us-east-1 \
     --owners self \
     --filters "Name=name,Values=SG-RUNNER-ami-*" \
     --output table
   ```

2. **Deregister AMI**:

   ```bash
   aws ec2 deregister-image \
     --region us-east-1 \
     --image-id ami-xxxxxxxxx
   ```

3. **Get Snapshot IDs**:

   ```bash
   aws ec2 describe-images \
     --region us-east-1 \
     --image-ids ami-xxxxxxxxx \
     --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' \
     --output text
   ```

4. **Delete Snapshots**:
   ```bash
   aws ec2 delete-snapshot \
     --region us-east-1 \
     --snapshot-id snap-xxxxxxxxx
   ```

### Option 3: AWS Console Cleanup

1. Navigate to **EC2 Dashboard** → **AMIs**
2. Filter by name: `SG-RUNNER-ami-*`
3. Select AMI and choose **Deregister AMI**
4. Navigate to **Snapshots** and delete associated snapshots

## Cost Considerations

- **AMI Storage**: ~$0.05 per GB-month for AMI storage
- **Snapshot Storage**: ~$0.05 per GB-month for EBS snapshots
- **Unused AMIs**: Can accumulate costs over time

## Automated Cleanup (Optional)

To enable automatic AMI cleanup during destroy, set:

```hcl
cleanup_amis_on_destroy = true

# Configure cleanup behavior
packer_config = {
  delete_snapshots = true  # Set to false to preserve snapshots
}
```

This will automatically deregister AMIs and delete snapshots, bypassing protection (except cooldown periods).

⚠️ **Warning**: Automatic cleanup is irreversible. Ensure no other resources depend on these AMIs.

## Troubleshooting

### AMI Deregistration Failed

- Check if AMI is being used by running instances
- Verify IAM permissions for `ec2:DeregisterImage`

### Snapshot Deletion Failed

- Ensure AMI is deregistered first
- Check for volumes created from the snapshot

### AWS CLI Not Found

- Install AWS CLI or use the AWS Console
- The pre-destroy script will warn but continue

## Files Generated

- `ami_cleanup_info.txt`: AMI details for manual cleanup
- `packer_manifest.log`: Packer build logs (if exists)

## Best Practices

1. **Regular Cleanup**: Remove unused AMIs monthly
2. **Naming Convention**: AMIs include timestamps for identification
3. **State Backup**: Always backup Terraform state before destroy
4. **Cost Monitoring**: Set up AWS billing alerts for AMI storage
