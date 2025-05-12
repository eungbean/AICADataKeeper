#!/bin/bash
# [05] 사용자 데이터 디렉토리 소유권/권한 정리
# 역할: 사용자 데이터 디렉토리 이하 전체 파일/디렉토리의 소유권을 설정

set -e

USERNAME=$1
GROUPNAME=${2:-users}
USER_DATA="/data/users/$USERNAME"

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 <username>"
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "[ERROR] 사용법: sudo $0 <username>"
  exit 1
fi

if [ ! -d "$USER_DATA" ]; then
  echo "[ERROR] 사용자 데이터 디렉토리가 없습니다: $USER_DATA"
  exit 1
fi

echo "[INFO] 소유권 설정 중: $USER_DATA"
find "$USER_DATA" -print0 | xargs -0 chown -f "$USERNAME:$GROUPNAME" 2>/dev/null || {
  echo "[WARNING] 일부 파일의 소유권 변경에 실패했습니다."
}

echo "[INFO] 소유권 설정 완료: $USER_DATA"