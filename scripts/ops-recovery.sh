#!/bin/bash
# [06-2] 자동 복구 오케스트레이터
# 역할: 서버 재부팅 후 글로벌 환경 및 등록된 모든 사용자 환경 자동 복구

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERS_FILE="/data/config/users.txt"
LOG_FILE="/var/log/aica-recovery.log"
DRY_RUN=false

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 [--dry-run]"
  exit 1
fi

if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
  echo "[INFO] DRY-RUN 모드: 실제 복구 작업을 수행하지 않습니다."
fi

log_message() {
  local MESSAGE="$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MESSAGE" | tee -a "$LOG_FILE"
}

log_message "========== AICA DataKeeper Auto Recovery Started =========="

if [ "$DRY_RUN" = true ]; then
  echo "[INFO] === 복구 계획 ==="
  echo "[INFO] 1. 글로벌 환경 복구 (Miniconda, 환경변수)"
  
  if [ ! -f "$USERS_FILE" ]; then
    echo "[INFO] 2. 등록된 사용자 없음 ($USERS_FILE 파일 없음)"
  else
    echo "[INFO] 2. 등록된 사용자 복구:"
    grep -v "^#" "$USERS_FILE" | grep -v "^$" | while IFS=: read -r USERNAME GROUPNAME; do
      echo "[INFO]    - $USERNAME:$GROUPNAME"
    done
  fi
  
  log_message "DRY-RUN 완료"
  exit 0
fi

log_message "Step 1: 글로벌 환경 복구 시작"
if "$SCRIPT_DIR/ops-setup-global.sh" gpu-users >> "$LOG_FILE" 2>&1; then
  log_message "Step 1: 글로벌 환경 복구 완료"
else
  log_message "[ERROR] Step 1: 글로벌 환경 복구 실패 (exit code: $?)"
fi

if [ ! -f "$USERS_FILE" ]; then
  log_message "등록된 사용자 없음 ($USERS_FILE 파일 없음)"
  log_message "========== AICA DataKeeper Auto Recovery Completed =========="
  exit 0
fi

log_message "Step 2: 등록된 사용자 복구 시작"
RECOVERY_COUNT=0
FAILED_COUNT=0

grep -v "^#" "$USERS_FILE" | grep -v "^$" | while IFS=: read -r USERNAME GROUPNAME; do
  if [ -z "$USERNAME" ] || [ -z "$GROUPNAME" ]; then
    log_message "[WARNING] 잘못된 형식: '$USERNAME:$GROUPNAME' (건너뜀)"
    continue
  fi
  
  log_message "사용자 복구 중: $USERNAME:$GROUPNAME"
  
  if "$SCRIPT_DIR/user-setup.sh" "$USERNAME" "$GROUPNAME" >> "$LOG_FILE" 2>&1; then
    log_message "사용자 $USERNAME 복구 완료"
    RECOVERY_COUNT=$((RECOVERY_COUNT + 1))
  else
    log_message "[ERROR] 사용자 $USERNAME 복구 실패 (exit code: $?)"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
done

log_message "Step 2: 사용자 복구 완료 (성공: $RECOVERY_COUNT, 실패: $FAILED_COUNT)"
log_message "========== AICA DataKeeper Auto Recovery Completed =========="

if [ $FAILED_COUNT -gt 0 ]; then
  exit 1
fi

exit 0
