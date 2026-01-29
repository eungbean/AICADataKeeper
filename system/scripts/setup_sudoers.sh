#!/bin/bash
# Setup sudoers configuration for selective sudo access
# Role: Grant gpu-users group NOPASSWD access to specific maintenance commands

set -e

GROUPNAME=${1:-gpu-users}
SUDOERS_FILE="/etc/sudoers.d/aica-datakeeper"

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script requires root privileges."
  echo "[ERROR] Usage: sudo $0 [groupname]"
  exit 1
fi

echo "[INFO] Setting up sudoers configuration for group: $GROUPNAME"

if ! getent group "$GROUPNAME" > /dev/null 2>&1; then
  echo "[ERROR] Group does not exist: $GROUPNAME"
  echo "[ERROR] Please create the group first or run setup_permissions.sh"
  exit 1
fi

SUDOERS_CONTENT="# AICADataKeeper sudoers configuration
# Allow $GROUPNAME to run specific maintenance commands without password

Cmnd_Alias CACHE_MGMT = /data/system/scripts/clean_cache.sh
Cmnd_Alias DISK_CHECK = /usr/bin/df

%$GROUPNAME ALL=(ALL) NOPASSWD: CACHE_MGMT, DISK_CHECK
"

if [ -f "$SUDOERS_FILE" ]; then
  EXISTING_CONTENT=$(cat "$SUDOERS_FILE")
  if [ "$EXISTING_CONTENT" = "$SUDOERS_CONTENT" ]; then
    echo "[INFO] Sudoers file already exists with correct content: $SUDOERS_FILE"
    exit 0
  else
    echo "[INFO] Sudoers file exists but content differs, updating: $SUDOERS_FILE"
  fi
fi

echo "[INFO] Creating sudoers file: $SUDOERS_FILE"
echo "$SUDOERS_CONTENT" > "$SUDOERS_FILE"

chmod 440 "$SUDOERS_FILE"
echo "[INFO] Set permissions to 440 (read-only for root and group)"

echo "[INFO] Validating sudoers syntax..."
if visudo -c -f "$SUDOERS_FILE"; then
  echo "[INFO] Sudoers syntax validation passed!"
else
  echo "[ERROR] Sudoers syntax validation failed!"
  echo "[ERROR] Removing invalid sudoers file: $SUDOERS_FILE"
  rm -f "$SUDOERS_FILE"
  exit 1
fi

echo "[INFO] ============================================"
echo "[INFO] Sudoers configuration completed!"
echo "[INFO] ============================================"
echo ""
echo "[INFO] Users in group '$GROUPNAME' can now run:"
echo "  - sudo /data/system/scripts/clean_cache.sh"
echo "  - sudo /usr/bin/df"
echo ""
echo "[INFO] Test with: sudo -u <username> sudo -n /data/system/scripts/clean_cache.sh --help"
