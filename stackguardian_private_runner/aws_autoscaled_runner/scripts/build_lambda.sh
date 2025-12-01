#!/bin/bash
set -e

echo "Building Lambda package..."

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/package"

echo "Cloning repository: $REPO_URL (branch: $REPO_BRANCH)"
git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$BUILD_DIR/repo"

# Copy Python source to package directory
# The lambda handler is typically in src/ or at the root
if [ -d "$BUILD_DIR/repo/src" ]; then
  echo "Copying src/ contents to package..."
  cp -r "$BUILD_DIR/repo/src/"* "$BUILD_DIR/package/"
elif [ -f "$BUILD_DIR/repo/lambda_function.py" ]; then
  echo "Copying lambda_function.py to package..."
  cp "$BUILD_DIR/repo/lambda_function.py" "$BUILD_DIR/package/"
elif [ -f "$BUILD_DIR/repo/main.py" ]; then
  echo "Copying main.py to package..."
  cp "$BUILD_DIR/repo/main.py" "$BUILD_DIR/package/"
else
  echo "Copying all Python files to package..."
  find "$BUILD_DIR/repo" -name "*.py" -exec cp {} "$BUILD_DIR/package/" \;
fi

# Install dependencies if requirements.txt exists
if [ -f "$BUILD_DIR/repo/requirements.txt" ]; then
  echo "Installing dependencies from requirements.txt..."
  pip install -r "$BUILD_DIR/repo/requirements.txt" -t "$BUILD_DIR/package/" --quiet --upgrade
fi

# Cleanup cloned repo to save space
rm -rf "$BUILD_DIR/repo"

echo "Lambda package built successfully at $BUILD_DIR/package"
