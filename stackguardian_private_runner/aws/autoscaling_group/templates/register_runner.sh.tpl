#!/usr/bin/env sh

set -e

startup_log_file="/tmp/sg_runner_startup.log"

## Mount the additional EBS volume to /var
## The volume is attached as the second device (typically nvme1n1 or xvdf)
echo ">> Setting up additional EBS volume for /var" | tee -a "$startup_log_file"

# Detect the device name - it could be nvme1n1 or xvdf depending on instance type
DATA_DEVICE=""
if [ -e /dev/nvme1n1 ]; then
  DATA_DEVICE="/dev/nvme1n1"
elif [ -e /dev/xvdf ]; then
  DATA_DEVICE="/dev/xvdf"
else
  echo ">> ERROR: Could not find additional EBS volume device. Shutting down instance." | tee -a "$startup_log_file"
  shutdown -h now
  exit 1
fi

echo ">> Found data device: $DATA_DEVICE" | tee -a "$startup_log_file"

# Check if the device is already formatted
if ! blkid "$DATA_DEVICE" > /dev/null 2>&1; then
  echo ">> Formatting $DATA_DEVICE with ext4 filesystem..." | tee -a "$startup_log_file"
  mkfs.ext4 -F "$DATA_DEVICE" 2>&1 | tee -a "$startup_log_file"
else
  echo ">> Device $DATA_DEVICE is already formatted." | tee -a "$startup_log_file"
fi

# Check if /var is already mounted to this device
if ! mountpoint -q /var || ! findmnt -n -o SOURCE /var | grep -q "$DATA_DEVICE"; then
  echo ">> Mounting $DATA_DEVICE to /var..." | tee -a "$startup_log_file"

  # Create temporary mount point
  TEMP_MOUNT="/mnt/temp_var"
  mkdir -p "$TEMP_MOUNT"

  # Mount the new volume temporarily
  mount "$DATA_DEVICE" "$TEMP_MOUNT" 2>&1 | tee -a "$startup_log_file"

  # Copy existing /var contents to the new volume (if not already copied)
  if [ ! -f "$TEMP_MOUNT/.var_migrated" ]; then
    echo ">> Copying existing /var contents to new volume..." | tee -a "$startup_log_file"
    rsync -av /var/ "$TEMP_MOUNT/" 2>&1 | tee -a "$startup_log_file"
    touch "$TEMP_MOUNT/.var_migrated"
  fi

  # Unmount temporary mount
  umount "$TEMP_MOUNT"

  # Mount to /var permanently
  mount "$DATA_DEVICE" /var 2>&1 | tee -a "$startup_log_file"

  # Update /etc/fstab if not already present
  if ! grep -q "$DATA_DEVICE" /etc/fstab; then
    echo ">> Adding $DATA_DEVICE to /etc/fstab..." | tee -a "$startup_log_file"
    echo "$DATA_DEVICE /var ext4 defaults,nofail 0 2" >> /etc/fstab
  fi

  echo ">> Successfully mounted $DATA_DEVICE to /var" | tee -a "$startup_log_file"
else
  echo ">> /var is already properly mounted." | tee -a "$startup_log_file"
fi

# Now that /var is mounted, update the log file location
startup_log_file="/var/log/sg_runner_startup.log"
echo ">> EBS volume setup complete. Continuing with runner registration..." | tee -a "$startup_log_file"

## Sometimes registration fails because `docker.service` is not ready.
## We will check if `docker.service` is ready and continue.
## Otherwise, sleep for 1 second and try again.
## Wait for Docker with same timeout as autoscaler scale_out_cooldown.
## If not provided, by default set to 5 minutes max
timeout="${sg_runner_startup_timeout}"
counter=0

until systemctl is-active --quiet docker; do
  echo ">> Docker not ready.. Trying again in 1 second." | tee -a "$startup_log_file"
  sleep 1
  counter=$((counter + 1))

  if [ $counter -ge $timeout ]; then
    echo ">> ERROR: Docker failed to start after $timeout seconds. Shutting down instance." | tee -a "$startup_log_file"
    shutdown -h now
  fi
done

## Register Private Runner
export SG_BASE_API="${sg_api_uri}/api/v1"
sg-runner register \
  --organization "${sg_org_name}" \
  --runner-group "${sg_runner_group_name}" \
  --sg-node-token "${sg_runner_group_token}" 2>&1 | tee -a "$startup_log_file"
