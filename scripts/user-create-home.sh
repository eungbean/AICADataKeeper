#!/bin/bash
# [03] 사용자 데이터 디렉토리 및 홈 심볼릭 링크 생성
# 역할: 신규 사용자의 데이터 디렉토리, 홈 디렉토리 심볼릭 링크, 백업 등을 처리

set -e

USERNAME=$1
GROUPNAME=${2:-users}
USER_HOME="/home/$USERNAME"
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

# 사용자명 검증 (영문, 숫자, _, - 만 허용)
if ! [[ "$USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "[ERROR] 잘못된 사용자명: $USERNAME"
  exit 1
fi

# 사용자 데이터 디렉토리 생성
if [ ! -d "$USER_DATA" ]; then
  mkdir -p "$USER_DATA" || { 
    echo "[ERROR] 디렉토리 생성 실패: $USER_DATA" 
    exit 1
  }
  chown "$USERNAME:$GROUPNAME" "$USER_DATA"
  chmod 750 "$USER_DATA"
  echo "[INFO] 사용자 데이터 디렉토리 생성: $USER_DATA"
fi

# 홈 디렉토리 심볼릭 링크 처리
if [ ! -L "$USER_HOME" ]; then
  if [ -d "$USER_HOME" ] && [ "$(ls -A "$USER_HOME" 2>/dev/null)" ]; then
    echo "[INFO] 기존 홈 디렉토리 내용을 $USER_DATA로 복사 중..."
    cp -a "$USER_HOME/." "$USER_DATA/" 2>/dev/null
    chown -R "$USERNAME:$GROUPNAME" "$USER_DATA"
    
    # 백업
    BACKUP_DIR="${USER_HOME}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$USER_HOME" "$BACKUP_DIR" || {
      echo "[ERROR] 기존 홈 디렉토리 백업 실패"
      exit 1
    }
    echo "[INFO] 홈 디렉토리 백업 완료: $BACKUP_DIR"
  fi
  
  ln -sf "$USER_DATA" "$USER_HOME" || {
    echo "[ERROR] 심볼릭 링크 생성 실패"
    exit 1
  }
  echo "[INFO] 심볼릭 링크 생성 완료: $USER_HOME -> $USER_DATA"
else
  # 심볼릭 링크가 올바른지 확인
  LINK_TARGET=$(readlink "$USER_HOME")
  if [ "$LINK_TARGET" != "$USER_DATA" ]; then
    rm "$USER_HOME"
    ln -sf "$USER_DATA" "$USER_HOME" || {
      echo "[ERROR] 심볼릭 링크 수정 실패"
      exit 1
    }
    echo "[INFO] 심볼릭 링크 수정 완료: $USER_HOME -> $USER_DATA"
  else
    echo "[INFO] 심볼릭 링크가 이미 올바르게 설정됨: $USER_HOME -> $USER_DATA"
  fi
fi