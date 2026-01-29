#!/bin/bash
set -e

# /data/system/scripts/setup_uv.sh
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

# 공식 설치 스크립트를 사용하여 uv 설치
# 이 스크립트는 /usr/local/bin/uv 또는 ~/.cargo/bin/uv에 설치합니다
if curl -LsSf https://astral.sh/uv/install.sh | sh; then
  echo "[INFO] uv installation completed successfully."
else
  echo "[ERROR] Failed to install uv via official installer."
  echo "[ERROR] Attempting fallback installation via pip..."
  
  # 폴백: pip를 통한 설치 (Miniconda가 설치되어 있어야 함)
  if command -v pip &> /dev/null; then
    pip install uv
    echo "[INFO] uv installed via pip."
  else
    echo "[ERROR] Neither curl installer nor pip is available."
    exit 1
  fi
fi

# uv 설치 확인
if ! command -v uv &> /dev/null; then
  echo "[ERROR] uv installation verification failed."
  exit 1
fi

echo "[INFO] uv version: $(uv --version)"

# 공유 캐시 디렉토리 생성
echo "[INFO] Setting up shared uv cache directory..."
mkdir -p /data/system/cache/uv

# 캐시 디렉토리 권한 설정
# 2775: setgid 비트 + 그룹 쓰기 가능 (새 파일도 그룹 소유권 유지)
chmod 2775 /data/system/cache/uv

# 소유권 설정 (root:gpu-users)
# gpu-users 그룹이 없으면 root:root로 설정
if getent group gpu-users &> /dev/null; then
  chown root:gpu-users /data/system/cache/uv
  echo "[INFO] Cache directory ownership set to root:gpu-users"
else
  echo "[WARNING] gpu-users group not found. Cache directory owned by root:root"
fi

# 캐시 디렉토리 권한 확인
echo "[INFO] Cache directory permissions:"
ls -ld /data/system/cache/uv

echo "[INFO] uv setup complete!"
echo "[INFO] To use uv with shared cache, ensure UV_CACHE_DIR is set:"
echo "[INFO]   export UV_CACHE_DIR=/data/system/cache/uv"
echo "[INFO] This is automatically set in /etc/profile.d/global_envs.sh"
