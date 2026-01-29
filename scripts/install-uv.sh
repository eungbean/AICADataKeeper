#!/bin/bash
set -e

# /data/scripts/install-uv.sh
# uv (fast Python package manager) 설치 및 공유 캐시 설정
# uv는 pip의 10-100배 빠른 대체 패키지 매니저로, 공유 캐시를 지원합니다.

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script requires root privileges."
  echo "[ERROR] Usage: sudo $0"
  exit 1
fi

# 이미 설치되어 있는지 확인 (멱등성)
if command -v uv &> /dev/null; then
  echo "[INFO] uv is already installed at $(command -v uv)"
  exit 0
fi

echo "[INFO] Installing uv (fast Python package manager)..."

UV_BIN="/usr/local/bin/uv"

if curl -LsSf https://astral.sh/uv/install.sh 2>/dev/null | INSTALLER_NO_MODIFY_PATH=1 sh -s -- --no-modify-path 2>/dev/null; then
  INSTALLED_PATH=$(find /root/.local/bin /root/.cargo/bin -name "uv" 2>/dev/null | head -1)
  if [ -n "$INSTALLED_PATH" ]; then
    mv "$INSTALLED_PATH" "$UV_BIN"
    chmod 755 "$UV_BIN"
    echo "[INFO] uv moved to $UV_BIN"
  fi
fi

if [ ! -f "$UV_BIN" ]; then
  echo "[INFO] Trying pip installation..."
  if command -v pip &> /dev/null; then
    pip install uv -q
    PIP_UV=$(pip show uv 2>/dev/null | grep "Location" | cut -d' ' -f2)
    if [ -n "$PIP_UV" ] && [ -f "$PIP_UV/../../../bin/uv" ]; then
      cp "$PIP_UV/../../../bin/uv" "$UV_BIN"
      chmod 755 "$UV_BIN"
    fi
  fi
fi

if [ ! -f "$UV_BIN" ]; then
  echo "[ERROR] uv installation failed"
  exit 1
fi

echo "[INFO] uv version: $($UV_BIN --version)"

# 공유 캐시 디렉토리 생성
echo "[INFO] Setting up shared uv cache directory..."
mkdir -p /data/cache/uv

# 캐시 디렉토리 권한 설정
# 2775: setgid 비트 + 그룹 쓰기 가능 (새 파일도 그룹 소유권 유지)
chmod 2775 /data/cache/uv

# 소유권 설정 (root:gpu-users)
# gpu-users 그룹이 없으면 root:root로 설정
if getent group gpu-users &> /dev/null; then
  chown root:gpu-users /data/cache/uv
  echo "[INFO] Cache directory ownership set to root:gpu-users"
else
  echo "[WARNING] gpu-users group not found. Cache directory owned by root:root"
fi

# 캐시 디렉토리 권한 확인
echo "[INFO] Cache directory permissions:"
ls -ld /data/cache/uv

echo "[INFO] uv setup complete!"
echo "[INFO] To use uv with shared cache, ensure UV_CACHE_DIR is set:"
echo "[INFO]   export UV_CACHE_DIR=/data/cache/uv"
echo "[INFO] This is automatically set in /etc/profile.d/global_envs.sh"
