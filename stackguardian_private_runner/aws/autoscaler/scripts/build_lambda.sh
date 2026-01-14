#!/bin/bash
set -e

echo "Building Lambda package..."

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/package"

echo "Cloning repository: $REPO_URL (branch: $REPO_BRANCH)"
git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$BUILD_DIR/repo"

# Copy all Python files from root to package directory
echo "Copying Python files to package..."
find "$BUILD_DIR/repo" -maxdepth 1 -name "*.py" -exec cp {} "$BUILD_DIR/package/" \;

# Install dependencies - prefer aws_requirements.txt for AWS Lambda
if [ -f "$BUILD_DIR/repo/aws_requirements.txt" ]; then
  echo "Installing dependencies from aws_requirements.txt..."
  pip install -r "$BUILD_DIR/repo/aws_requirements.txt" -t "$BUILD_DIR/package/" --quiet --upgrade
elif [ -f "$BUILD_DIR/repo/requirements.txt" ]; then
  echo "Installing dependencies from requirements.txt..."
  pip install -r "$BUILD_DIR/repo/requirements.txt" -t "$BUILD_DIR/package/" --quiet --upgrade
fi

# Cleanup cloned repo to save space
rm -rf "$BUILD_DIR/repo"

echo "Lambda package built successfully at $BUILD_DIR/package"
