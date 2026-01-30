#!/bin/bash
# [03-v2] 사용자 홈 디렉토리 설정 (하이브리드 아키텍처)
# 역할: SSD에 실제 홈 디렉토리 생성, NFS 데이터 디렉토리 연결

set -e

USERNAME=$1
GROUPNAME=${2:-gpu-users}
DRY_RUN=false

# Parse --dry-run flag
for arg in "$@"; do
  if [ "$arg" == "--dry-run" ]; then
    DRY_RUN=true
  fi
done

USER_HOME="/home/$USERNAME"
USER_DATA="/data/users/$USERNAME"
USER_DOTFILES="$USER_DATA/dotfiles"
HOME_DATA_LINK="$USER_HOME/data"

# Root check
if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 <username> [groupname] [--dry-run]"
  exit 1
fi

# Username validation
if [ -z "$USERNAME" ]; then
  echo "[ERROR] 사용법: sudo $0 <username> [groupname] [--dry-run]"
  exit 1
fi

# 사용자명 검증 (영문, 숫자, _, - 만 허용)
if ! [[ "$USERNAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "[ERROR] 잘못된 사용자명: $USERNAME"
  exit 1
fi

# Dry run mode information
if [ "$DRY_RUN" = true ]; then
  echo "[INFO] DRY RUN 모드: 실제로는 실행하지 않고 표시만 합니다."
fi

# Function to execute or show command based on dry-run mode
execute_or_show() {
  local cmd="$1"
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] $cmd"
  else
    echo "[EXEC] $cmd"
    eval "$cmd" || {
      echo "[ERROR] 명령어 실행 실패: $cmd"
      exit 1
    }
  fi
}

# 1. 사용자 데이터 디렉토리 생성
if [ ! -d "$USER_DATA" ]; then
  execute_or_show "mkdir -p \"$USER_DATA\""
  execute_or_show "chown \"$USERNAME:$GROUPNAME\" \"$USER_DATA\""
  execute_or_show "chmod 750 \"$USER_DATA\""
  echo "[INFO] 사용자 데이터 디렉토리 생성: $USER_DATA"
else
  echo "[INFO] 사용자 데이터 디렉토리가 이미 존재함: $USER_DATA"
fi

# 2. dotfiles 디렉토리 생성
if [ ! -d "$USER_DOTFILES" ]; then
  execute_or_show "mkdir -p \"$USER_DOTFILES\""
  execute_or_show "chown \"$USERNAME:$GROUPNAME\" \"$USER_DOTFILES\""
  execute_or_show "chmod 750 \"$USER_DOTFILES\""
  echo "[INFO] dotfiles 디렉토리 생성: $USER_DOTFILES"
else
  echo "[INFO] dotfiles 디렉토리가 이미 존재함: $USER_DOTFILES"
fi

# 3. SSD 홈 디렉토리 생성 (실제 디렉토리, 심볼릭 링크 아님)
if [ ! -d "$USER_HOME" ]; then
  execute_or_show "mkdir -p \"$USER_HOME\""
  execute_or_show "chown \"$USERNAME:$GROUPNAME\" \"$USER_HOME\""
  execute_or_show "chmod 750 \"$USER_HOME\""
  echo "[INFO] SSD 홈 디렉토리 생성: $USER_HOME"
elif [ -L "$USER_HOME" ]; then
  echo "[WARNING] $USER_HOME 이 심볼릭 링크입니다. v1 아키텍처에서 마이그레이션이 필요할 수 있습니다."
  LINK_TARGET=$(readlink "$USER_HOME")
  echo "[INFO] 현재 심볼릭 링크 대상: $USER_HOME -> $LINK_TARGET"
fi

# 4. ~/data 심볼릭 링크 생성 (/home/username/data -> /data/users/username)
if [ ! -L "$HOME_DATA_LINK" ]; then
  if [ -e "$HOME_DATA_LINK" ]; then
    echo "[WARNING] $HOME_DATA_LINK 이/가 이미 존재합니다. 백업 후 생성합니다."
    BACKUP_PATH="${HOME_DATA_LINK}.bak.$(date +%Y%m%d%H%M%S)"
    execute_or_show "mv \"$HOME_DATA_LINK\" \"$BACKUP_PATH\""
  fi
  execute_or_show "ln -sf \"$USER_DATA\" \"$HOME_DATA_LINK\""
  echo "[INFO] ~/data 심볼릭 링크 생성: $HOME_DATA_LINK -> $USER_DATA"
else
  # 심볼릭 링크가 올바른지 확인
  LINK_TARGET=$(readlink "$HOME_DATA_LINK")
  if [ "$LINK_TARGET" != "$USER_DATA" ]; then
    echo "[INFO] ~/data 심볼릭 링크가 올바르지 않습니다. 수정합니다."
    execute_or_show "rm \"$HOME_DATA_LINK\""
    execute_or_show "ln -sf \"$USER_DATA\" \"$HOME_DATA_LINK\""
    echo "[INFO] ~/data 심볼릭 링크 수정 완료: $HOME_DATA_LINK -> $USER_DATA"
  else
    echo "[INFO] ~/data 심볼릭 링크가 이미 올바르게 설정됨: $HOME_DATA_LINK -> $USER_DATA"
  fi
fi

# 5. 최종 권한 확인 및 설정
if [ "$DRY_RUN" != true ]; then
  # 실제 실행 시에만 권한 확인
  echo "[INFO] 최종 권한 설정 확인..."
  
  # 홈 디렉토리 권한 확인
  if [ -d "$USER_HOME" ]; then
    CURRENT_PERM=$(stat -c "%a" "$USER_HOME")
    if [ "$CURRENT_PERM" != "750" ]; then
      execute_or_show "chmod 750 \"$USER_HOME\""
    fi
    execute_or_show "chown \"$USERNAME:$GROUPNAME\" \"$USER_HOME\""
  fi
  
  # 데이터 디렉토리 권한 확인
  if [ -d "$USER_DATA" ]; then
    CURRENT_PERM=$(stat -c "%a" "$USER_DATA")
    if [ "$CURRENT_PERM" != "750" ]; then
      execute_or_show "chmod 750 \"$USER_DATA\""
    fi
    execute_or_show "chown \"$USERNAME:$GROUPNAME\" \"$USER_DATA\""
  fi
  
  # dotfiles 디렉토리 권한 확인
  if [ -d "$USER_DOTFILES" ]; then
    CURRENT_PERM=$(stat -c "%a" "$USER_DOTFILES")
    if [ "$CURRENT_PERM" != "750" ]; then
      execute_or_show "chmod 750 \"$USER_DOTFILES\""
    fi
    execute_or_show "chown \"$USERNAME:$GROUPNAME\" \"$USER_DOTFILES\""
  fi
fi

echo "[INFO] 사용자 홈 디렉토리 v2 설정 완료: $USERNAME"
echo "[INFO] - SSD 홈 디렉토리: $USER_HOME (실제 디렉토리)"
echo "[INFO] - 데이터 디렉토리: $USER_DATA"
echo "[INFO] - ~/data 심볼릭 링크: $HOME_DATA_LINK -> $USER_DATA"
echo "[INFO] - dotfiles 디렉토리: $USER_DOTFILES"