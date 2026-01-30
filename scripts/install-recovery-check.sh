#!/bin/bash
# Recovery check installer
# Creates /etc/profile.d/00-recovery-check.sh

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  exit 1
fi

PROFILE_SCRIPT="/etc/profile.d/00-recovery-check.sh"

cat > "$PROFILE_SCRIPT" << 'EOF'
#!/bin/bash
# 00-recovery-check.sh - Wait for recovery service completion
# Part of AICADataKeeper

# Skip if explicitly requested
if [ "${SKIP_RECOVERY_WAIT:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi

RECOVERY_FLAG="/tmp/recovery-complete"
MAX_WAIT=30
WAIT_INTERVAL=1

# Only check for interactive shells
if [ -z "$PS1" ]; then
    return 0 2>/dev/null || exit 0
fi

# Check if recovery flag exists
if [ -f "$RECOVERY_FLAG" ]; then
    return 0 2>/dev/null || exit 0
fi

# Wait for recovery to complete
echo "[INFO] Waiting for system recovery to complete..."
waited=0
while [ ! -f "$RECOVERY_FLAG" ] && [ $waited -lt $MAX_WAIT ]; do
    sleep $WAIT_INTERVAL
    waited=$((waited + WAIT_INTERVAL))
done

if [ ! -f "$RECOVERY_FLAG" ]; then
    echo "[WARNING] Recovery did not complete within ${MAX_WAIT}s. Environment may be incomplete."
    echo "[WARNING] If issues persist, contact system administrator."
fi
EOF

chmod 644 "$PROFILE_SCRIPT"
echo "[INFO] Recovery check script installed: $PROFILE_SCRIPT"