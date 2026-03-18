#!/bin/sh
set -e

echo "Building Cloud Function package..."

# Clean and create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/package"

echo "Cloning repository: $REPO_URL (branch: $REPO_BRANCH)"
git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$BUILD_DIR/repo"
CLONED_COMMIT=$(git -C "$BUILD_DIR/repo" rev-parse HEAD)
echo "Cloned commit: $CLONED_COMMIT"

# Copy all Python files from root to package directory
echo "Copying Python files to package..."
find "$BUILD_DIR/repo" -maxdepth 1 -name "*.py" -exec cp {} "$BUILD_DIR/package/" \;

# Install dependencies using virtual environment to avoid system package conflicts
if [ -f "$BUILD_DIR/repo/gcp_requirements.txt" ]; then
  echo "Installing dependencies from gcp_requirements.txt..."
  python3 -m venv "$BUILD_DIR/.venv"
  . "$BUILD_DIR/.venv/bin/activate"
  pip install -r "$BUILD_DIR/repo/gcp_requirements.txt" -t "$BUILD_DIR/package/" --quiet --upgrade
  deactivate
elif [ -f "$BUILD_DIR/repo/requirements.txt" ]; then
  echo "Installing dependencies from requirements.txt..."
  python3 -m venv "$BUILD_DIR/.venv"
  . "$BUILD_DIR/.venv/bin/activate"
  pip install -r "$BUILD_DIR/repo/requirements.txt" -t "$BUILD_DIR/package/" --quiet --upgrade
  deactivate
fi

# Cleanup temporary directories
rm -rf "$BUILD_DIR/repo" "$BUILD_DIR/.venv"

# Create Cloud Function deployment zip using Python (zip command may not be available)
echo "Creating Cloud Function zip package..."
python3 -c "
import zipfile
import os

package_dir = '$BUILD_DIR/package'
zip_path = '$BUILD_DIR/function.zip'

with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(package_dir):
        for file in files:
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, package_dir)
            zf.write(file_path, arcname)
"

# Cleanup package directory
rm -rf "$BUILD_DIR/package"

echo "Cloud Function package built successfully at $BUILD_DIR/function.zip"
