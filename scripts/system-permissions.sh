#!/bin/bash
# Setup permissions for shared directories using setgid + umask
# Role: Apply setgid and group permissions to shared cache and model directories

set -e

GROUPNAME=${1:-gpu-users}

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script requires root privileges."
  echo "[ERROR] Usage: sudo $0 [groupname]"
  exit 1
fi

echo "[INFO] Setting up permissions for group: $GROUPNAME"
echo "[INFO] Using setgid + umask 002 (NFS v3 compatible)"

if ! getent group "$GROUPNAME" > /dev/null 2>&1; then
  echo "[INFO] Creating group: $GROUPNAME"
  groupadd "$GROUPNAME"
else
  echo "[INFO] Group already exists: $GROUPNAME"
fi

CACHE_DIRS=(
  "/data/cache/pip"
  "/data/cache/conda/pkgs"
  "/data/cache/npm"
  "/data/cache/yarn"
  "/data/cache/python"
  "/data/cache/uv"
)

MODEL_DIRS=(
  "/data/models/torch"
  "/data/models/huggingface"
  "/data/models/comfyui"
  "/data/models/flux"
)

ALL_DIRS=("${CACHE_DIRS[@]}" "${MODEL_DIRS[@]}")

apply_permissions() {
  local dir=$1
  
  if [ ! -d "$dir" ]; then
    echo "[WARNING] Directory does not exist, skipping: $dir"
    return
  fi
  
  echo "[INFO] Applying permissions to: $dir"
  
  chgrp -R "$GROUPNAME" "$dir" 2>/dev/null || {
    echo "[WARNING] Failed to change group ownership for some files in: $dir"
  }
  
  chmod 2775 "$dir"
  
  find "$dir" -type d -exec chmod 2775 {} \; 2>/dev/null || {
    echo "[WARNING] Failed to set permissions for some directories in: $dir"
  }
  
  find "$dir" -type f -exec chmod 664 {} \; 2>/dev/null || {
    echo "[WARNING] Failed to set permissions for some files in: $dir"
  }
  
  echo "[INFO] Permissions applied successfully to: $dir"
}

echo "[INFO] Starting permission setup..."
echo ""

for dir in "${ALL_DIRS[@]}"; do
  apply_permissions "$dir"
  echo ""
done

echo "[INFO] ============================================"
echo "[INFO] Permission setup completed!"
echo "[INFO] ============================================"
echo ""
echo "[INFO] Verification commands:"
echo "  - Check setgid: ls -ld $dir | grep '^d.*s'"
echo "  - Check group: ls -ld $dir"
echo ""
echo "[INFO] Users in group '$GROUPNAME' now have read/write/execute access to shared directories."
echo "[INFO] New files will automatically inherit group ownership (setgid)."
echo ""
echo "[IMPORTANT] Each user must set 'umask 002' in their ~/.bashrc for group write permissions:"
echo "  echo 'umask 002' >> ~/.bashrc"
echo "  source ~/.bashrc"
