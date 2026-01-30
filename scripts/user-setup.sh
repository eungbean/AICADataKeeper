#!/bin/bash
# [00] 사용자 환경 설정/복구 wrapper (v2 아키텍처)
# 역할: 신규 사용자 설정 또는 재시작 후 기존 사용자 복구
# 
# v2 아키텍처:
#   /home/<user>/           (SSD - 실제 디렉토리)
#   /home/<user>/data/  ->  /data/users/<user>/  (심볼릭 링크)
#   ~/.bashrc           ->  ~/data/dotfiles/.bashrc (심볼릭 링크)

set -e

# 스크립트 위치 기준 절대 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME=$1
GROUPNAME=${2:-users}
SHELL_CHOICE=${3:-bash}

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 <username> <groupname> [shell]"
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "[ERROR] 사용법: sudo $0 <username> <groupname> [shell]"
  exit 1
fi

# v2 아키텍처: SSD 홈 + NFS 데이터 디렉토리
"$SCRIPT_DIR/user-create-home-v2.sh" "$USERNAME" "$GROUPNAME" || { echo "[ERROR] 사용자 홈 디렉토리 생성 실패"; exit 1; }

# dotfile 심볼릭 링크 설정 (v2)
"$SCRIPT_DIR/user-setup-dotfiles.sh" "$USERNAME" "$GROUPNAME" || { echo "[ERROR] dotfile 설정 실패"; exit 1; }

# 쉘 설정 (bash/zsh)
"$SCRIPT_DIR/user-setup-shell.sh" "$USERNAME" "$SHELL_CHOICE" "$GROUPNAME" || { echo "[ERROR] 사용자 쉘 설정 실패"; exit 1; }

# Conda 설정
"$SCRIPT_DIR/user-setup-conda.sh" "$USERNAME" "$GROUPNAME" || { echo "[ERROR] 사용자 Conda 설정 실패"; exit 1; }

# 권한 설정
"$SCRIPT_DIR/user-fix-permissions.sh" "$USERNAME" "$GROUPNAME" || { echo "[ERROR] 사용자 권한 설정 실패"; exit 1; }

echo "[INFO] 사용자 $USERNAME 설정/복구 완료 (v2 아키텍처)."