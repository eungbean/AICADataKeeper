#!/bin/bash
set -e

# /data/scripts/install-bun.sh
# Bun (JavaScript runtime/package manager) 시스템 전체 설치
# NFS 홈 환경에서는 config/global_env.sh의 BUN_INSTALL_CACHE_DIR로 캐시를 로컬에 둠 (BUN_REPORT.md 참고).

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script requires root privileges."
  echo "[ERROR] Usage: sudo $0"
  exit 1
fi

BUN_SYSTEM_BIN="/usr/local/bin/bun"
if [ -x "$BUN_SYSTEM_BIN" ]; then
  echo "[INFO] Bun is already installed at $BUN_SYSTEM_BIN ($($BUN_SYSTEM_BIN --version 2>/dev/null || true))"
  exit 0
fi

echo "[INFO] Installing Bun (JavaScript runtime & package manager)..."

INSTALL_DIR="/usr/local/lib/bun"
mkdir -p "$INSTALL_DIR"

# 공식 설치 스크립트: 설치 경로만 지정, PATH는 수정하지 않음
export BUN_INSTALL="$INSTALL_DIR"
if ! curl -fsSL https://bun.sh/install | bash -s -- --no-modify-path 2>/dev/null; then
  echo "[WARNING] Install script may have modified PATH; checking for binary..."
fi

BUN_BIN="$INSTALL_DIR/bin/bun"
if [ ! -x "$BUN_BIN" ]; then
  echo "[ERROR] Bun binary not found at $BUN_BIN"
  exit 1
fi

# 시스템 PATH에 노출 (모든 사용자가 bun 사용 가능)
ln -sf "$BUN_BIN" "$BUN_SYSTEM_BIN"
if [ -x "$INSTALL_DIR/bin/bunx" ]; then
  ln -sf "$INSTALL_DIR/bin/bunx" /usr/local/bin/bunx
fi

echo "[INFO] Bun version: $($BUN_SYSTEM_BIN --version)"
echo "[INFO] Bun installed at $BUN_SYSTEM_BIN (system-wide)."
echo "[INFO] NFS home users: ensure global_env.sh is loaded (BUN_INSTALL_CACHE_DIR). See BUN_REPORT.md."
