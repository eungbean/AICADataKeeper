#!/bin/bash
# [00] 사용자 환경 설정/복구 wrapper
# 역할: 신규 사용자 설정 또는 재시작 후 기존 사용자 복구

set -e

# 스크립트 위치 기준 절대 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME=$1
GROUPNAME=${2:-users}

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 <username> <groupname>"
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "[ERROR] 사용법: sudo $0 <username> <groupname>"
  exit 1
fi

# 사용자별 세팅
"$SCRIPT_DIR/3_create_user_data_dir.sh" "$USERNAME" "$GROUPNAME" || { echo "[ERROR] 사용자 데이터 디렉토리 생성 실패"; exit 1; }
"$SCRIPT_DIR/4_setup_user_conda.sh" "$USERNAME" "$GROUPNAME" || { echo "[ERROR] 사용자 Conda 설정 실패"; exit 1; }
"$SCRIPT_DIR/5_fix_user_permission.sh" "$USERNAME" "$GROUPNAME" || { echo "[ERROR] 사용자 권한 설정 실패"; exit 1; }

echo "[INFO] 사용자 $USERNAME 설정/복구 완료."