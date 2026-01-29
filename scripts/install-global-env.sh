#!/bin/bash
# [02] 시스템 환경 변수 스크립트 설치
# 역할: /etc/profile.d/global_envs.sh에 공통 환경 변수를 source하는 로더 스크립트 생성

set -e

# 스크립트 디렉토리 기준 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GROUPNAME=${2:-users}

# 공유 캐시/모델 폴더 생성 (pip/uv/npm/yarn은 개인 ~/.cache 사용)
mkdir -p /data/cache/conda/pkgs
mkdir -p /data/models/{torch,huggingface/hub,huggingface/datasets,comfyui,flux}

# setgid + 그룹 쓰기 권한 설정
chmod -R 2775 /data/cache/conda
chmod -R 2775 /data/models

# 그룹 소유권 설정
chown -R root:$GROUPNAME /data/cache/conda
chown -R root:$GROUPNAME /data/models

# 환경 변수 파일 경로 (스크립트 디렉토리 기준)
GLOBAL_ENV="$SCRIPT_DIR/../config/global_env.sh"
ENV_DST="/etc/profile.d/global_envs.sh"

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 $GROUPNAME"
  exit 1
fi

# 환경 변수 파일 존재 확인
if [ ! -f "$GLOBAL_ENV" ]; then
  echo "[ERROR] 환경 변수 파일이 없습니다: $GLOBAL_ENV"
  exit 1
fi

if [ -f "$ENV_DST" ]; then
  echo "[INFO] $ENV_DST already exists. Skipping."
  exit 0
fi

echo "[INFO] 환경 변수 로더 스크립트를 $ENV_DST에 설치 중..."
if ! tee "$ENV_DST" > /dev/null << EOF
# Load shared environment variables
if [ -f "$GLOBAL_ENV" ]; then
  source "$GLOBAL_ENV"
fi
EOF
then
  echo "[ERROR] 환경 변수 로더 스크립트 생성 실패"
  exit 1
fi

chmod 644 "$ENV_DST"
echo "[INFO] 환경 변수 설정 완료"
echo "[INFO] 시스템 재시작 없이 바로 적용하려면: source $ENV_DST"