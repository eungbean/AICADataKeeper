#!/bin/bash
# [01] 글로벌 Miniconda3 설치
# 역할: 서버 전체에서 사용할 글로벌 Miniconda3를 /data/apps/miniconda3에 설치

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 [설치경로]"
  exit 1
fi

MINICONDA_PATH=${1:-"/data/apps/miniconda3"}
MINICONDA_INSTALLER="Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_URL="https://repo.anaconda.com/miniconda/$MINICONDA_INSTALLER"
DOWNLOAD_PATH="/tmp/$MINICONDA_INSTALLER"

# 이미 설치되어 있는지 확인
if [ -d "$MINICONDA_PATH" ]; then
  echo "[INFO] Miniconda가 이미 $MINICONDA_PATH에 설치되어 있습니다."
  exit 0
fi

echo "[INFO] Miniconda 다운로드 중..."
wget -q "$MINICONDA_URL" -O "$DOWNLOAD_PATH" || { 
  echo "[ERROR] Miniconda 다운로드 실패" 
  exit 1
}

echo "[INFO] Miniconda를 $MINICONDA_PATH에 설치 중..."
bash "$DOWNLOAD_PATH" -b -p "$MINICONDA_PATH" || { 
  echo "[ERROR] Miniconda 설치 실패" 
  exit 1
}

rm -f "$DOWNLOAD_PATH"
chmod -R 755 "$MINICONDA_PATH"

echo "[INFO] Miniconda 초기 설정 중..."
$MINICONDA_PATH/bin/conda config --system --set auto_activate_base false
$MINICONDA_PATH/bin/conda config --system --set channel_priority flexible
$MINICONDA_PATH/bin/conda config --system --prepend channels conda-forge

# 공유 캐시 디렉토리 생성
mkdir -p /data/cache/conda/pkgs
chmod 2775 /data/cache/conda/pkgs  # setgid bit for group inheritance

echo "[INFO] Miniconda 설치 완료: $MINICONDA_PATH"