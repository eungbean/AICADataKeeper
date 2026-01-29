#!/bin/bash
# [01] 글로벌 환경 복구
# 역할: 시스템 재시작 후 글로벌 환경 복구

set -e

# 스크립트 위치 기준 절대 경로 설정
GROUPNAME=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINICONDA_PATH="/data/system/apps/miniconda3"
ENV_DST="/etc/profile.d/global_envs.sh"

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0"
  exit 1
fi

# 글로벌 Miniconda 설치 (최초 1회만 필요)
if [ -d "$MINICONDA_PATH" ]; then
  echo "[INFO] Miniconda already installed at $MINICONDA_PATH"
else
  "$SCRIPT_DIR/1_install_miniconda3_global.sh" "$MINICONDA_PATH" || { 
    echo "[ERROR] Miniconda 설치 실패"
    exit 1
  }
fi

# 환경 변수 스크립트 설치 (최초 1회만 필요)
if [ -f "$ENV_DST" ]; then
  echo "[INFO] $ENV_DST already exists. Skipping."
else
  "$SCRIPT_DIR/2_install_global_env.sh" "$GROUPNAME" || {
    echo "[ERROR] 환경 변수 설정 실패"
    exit 1
  }
fi

echo "[INFO] 글로벌 환경 복구 완료"