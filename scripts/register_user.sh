#!/bin/bash
# [06-1] 사용자 등록 관리
# 역할: users.txt에 사용자 추가/제거하여 자동 복구 대상 관리

set -e

USERNAME=$1
GROUPNAME=${2:-users}
USERS_FILE="/data/config/users.txt"

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 <username> [groupname]"
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "[ERROR] 사용자명이 제공되지 않았습니다."
  echo "[ERROR] 사용법: sudo $0 <username> [groupname]"
  exit 1
fi

# users.txt 파일이 없으면 생성
if [ ! -f "$USERS_FILE" ]; then
  echo "[INFO] $USERS_FILE 파일이 없습니다. 새로 생성합니다."
  mkdir -p "$(dirname "$USERS_FILE")"
  cat > "$USERS_FILE" <<EOF
# AICADataKeeper Registered Users
# 이 파일은 auto_recovery.sh가 서버 재부팅 후 자동으로 복구할 사용자 목록입니다.
# Format: username:groupname
# 주석은 #으로 시작합니다.

EOF
fi

# 중복 체크
if grep -q "^${USERNAME}:" "$USERS_FILE"; then
  echo "[INFO] 사용자 $USERNAME:$GROUPNAME 이미 등록되어 있습니다."
  exit 0
fi

# 사용자 추가
echo "${USERNAME}:${GROUPNAME}" >> "$USERS_FILE"
echo "[INFO] 사용자 $USERNAME:$GROUPNAME 이 $USERS_FILE 에 등록되었습니다."
echo "[INFO] 다음 재부팅 시 자동으로 복구됩니다."
