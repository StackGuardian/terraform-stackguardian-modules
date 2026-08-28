#!/bin/sh
set -e

echo "Deploying autoscaler function code..."

TEMP_DIR=$(mktemp -d)
# Always clean up, including when set -e aborts the script early
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "Cloning repository: $REPO_URL (branch: $REPO_BRANCH)"
git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$TEMP_DIR/repo"
CLONED_COMMIT=$(git -C "$TEMP_DIR/repo" rev-parse HEAD)
echo "Cloned commit: $CLONED_COMMIT"

cd "$TEMP_DIR/repo"
cp azure_requirements.txt requirements.txt

# Create deployment package
echo "Creating deployment package..."
zip -r "$TEMP_DIR/deploy.zip" . -x ".git/*"

# Deploy using Azure CLI
# Exit codes 1/3 = health check or SyncTrigger timeout after successful
# upload (known issue with Flex Consumption plans). Tolerate them; fail
# on anything else.
set +e
az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$FUNCTION_APP_NAME" \
  --src "$TEMP_DIR/deploy.zip" \
  --build-remote true \
  --timeout 300
AZ_EXIT=$?
set -e
if [ "$AZ_EXIT" -ne 0 ] && [ "$AZ_EXIT" -ne 1 ] && [ "$AZ_EXIT" -ne 3 ]; then
  echo "ERROR: Deployment failed with exit code $AZ_EXIT"
  exit "$AZ_EXIT"
fi

echo "Function code deployed successfully to $FUNCTION_APP_NAME"
