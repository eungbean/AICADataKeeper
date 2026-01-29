#!/bin/bash
# Setup ACL-based permissions for shared directories
# Role: Apply ACL and setgid to shared cache and model directories

set -e

GROUPNAME=${1:-gpu-users}

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script requires root privileges."
  echo "[ERROR] Usage: sudo $0 [groupname]"
  exit 1
fi

echo "[INFO] Setting up ACL-based permissions for group: $GROUPNAME"

# Create group if not exists
if ! getent group "$GROUPNAME" > /dev/null 2>&1; then
  echo "[INFO] Creating group: $GROUPNAME"
  groupadd "$GROUPNAME"
else
  echo "[INFO] Group already exists: $GROUPNAME"
fi

# Define shared directories
CACHE_DIRS=(
  "/data/system/cache/pip"
  "/data/system/cache/conda/pkgs"
  "/data/system/cache/npm"
  "/data/system/cache/yarn"
  "/data/system/cache/python"
  "/data/system/cache/uv"
)

MODEL_DIRS=(
  "/data/models/torch"
  "/data/models/huggingface"
  "/data/models/comfyui"
  "/data/models/flux"
)

ALL_DIRS=("${CACHE_DIRS[@]}" "${MODEL_DIRS[@]}")

# Function to apply ACL permissions to a directory
apply_acl_permissions() {
  local dir=$1
  
  if [ ! -d "$dir" ]; then
    echo "[WARNING] Directory does not exist, skipping: $dir"
    return
  fi
  
  echo "[INFO] Applying ACL permissions to: $dir"
  
  # Set group ownership (keep current owner, just set group)
  chgrp -R "$GROUPNAME" "$dir" 2>/dev/null || {
    echo "[WARNING] Failed to change group ownership for some files in: $dir"
  }
  
  # Set setgid bit (2775 = rwxrwsr-x)
  # This ensures new files inherit the group
  chmod 2775 "$dir"
  
  # Set default ACL for new files (inheritance)
  # -d = default ACL applies to new files/directories
  # -m = modify ACL
  # g:groupname:rwx = group gets read/write/execute
  setfacl -d -m "g:$GROUPNAME:rwx" "$dir" 2>/dev/null || {
    echo "[ERROR] Failed to set default ACL on: $dir"
    echo "[ERROR] Make sure the filesystem supports ACL (mount with 'acl' option)"
    return 1
  }
  
  # Set current ACL for existing files
  # -R = recursive
  # X (capital) = execute only on directories, not files
  setfacl -R -m "g:$GROUPNAME:rwX" "$dir" 2>/dev/null || {
    echo "[WARNING] Failed to set ACL for some existing files in: $dir"
  }
  
  echo "[INFO] ACL permissions applied successfully to: $dir"
}

# Apply permissions to all directories
echo "[INFO] Starting ACL permission setup..."
echo ""

for dir in "${ALL_DIRS[@]}"; do
  apply_acl_permissions "$dir"
  echo ""
done

echo "[INFO] ============================================"
echo "[INFO] ACL permission setup completed!"
echo "[INFO] ============================================"
echo ""
echo "[INFO] Verification commands:"
echo "  - Check ACL: getfacl $dir"
echo "  - Check setgid: ls -ld $dir | grep '^d.*s'"
echo "  - Check group: ls -ld $dir"
echo ""
echo "[INFO] Users in group '$GROUPNAME' now have read/write/execute access to shared directories."
echo "[INFO] New files will automatically inherit group ownership and permissions."
