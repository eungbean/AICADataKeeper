#!/bin/bash
# [04] 사용자별 Conda 환경 및 설정
# 역할: 신규 사용자의 conda 환경 디렉토리, .condarc 설정, conda init 등 준비

set -e

USERNAME=$1
GROUPNAME=${2:-users}

USER_HOME="/home/$USERNAME"
USER_DATA="/data/users/$USERNAME"
MINICONDA_PATH="/data/system/apps/miniconda3"

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 <username>"
  exit 1
fi

if [ -z "$USERNAME" ]; then
  echo "[ERROR] 사용법: sudo $0 <username>"
  exit 1
fi

if [ ! -d "$MINICONDA_PATH" ]; then
  echo "[ERROR] Miniconda가 설치되어 있지 않습니다: $MINICONDA_PATH"
  exit 1
fi

if [ ! -d "$USER_DATA" ]; then
  echo "[ERROR] 사용자 데이터 디렉토리가 없습니다: $USER_DATA"
  exit 1
fi

# Conda 환경 디렉토리
mkdir -p "$USER_DATA/.conda/envs" || {
  echo "[ERROR] Conda 환경 디렉토리 생성 실패"
  exit 1
}
chown -R "$USERNAME:$GROUPNAME" "$USER_DATA/.conda"

# Conda 설정 파일
cat > "$USER_DATA/.condarc" << EOF || {
  echo "[ERROR] .condarc 파일 생성 실패"
  exit 1
}
channels:
  - conda-forge
  - defaults
auto_activate_base: false
envs_dirs:
  - $USER_DATA/.conda/envs
pkgs_dirs:
  - /data/system/cache/conda/pkgs
EOF

chown "$USERNAME:$GROUPNAME" "$USER_DATA/.condarc"

# 사용자별 환경 변수 설정
USER_SHELL=$(getent passwd $USERNAME | cut -d: -f7)
SHELL_RC=""

if [[ "$USER_SHELL" == *"bash"* ]]; then
  SHELL_RC="$USER_DATA/.bashrc"
  sudo -u "$USERNAME" "$MINICONDA_PATH/bin/conda" init bash || {
    echo "[ERROR] Conda bash 초기화 실패"
    exit 1
  }
  echo "[INFO] Conda initialized for bash"
fi

if [[ "$USER_SHELL" == *"zsh"* ]]; then
  SHELL_RC="$USER_DATA/.zshrc"
  sudo -u "$USERNAME" "$MINICONDA_PATH/bin/conda" init zsh || {
    echo "[ERROR] Conda zsh 초기화 실패"
    exit 1
  }
  echo "[INFO] Conda initialized for zsh"
fi

# 사용자별 환경 변수 추가
if [ -n "$SHELL_RC" ]; then
  cat >> "$SHELL_RC" << EOF || {
    echo "[ERROR] 사용자 쉘 설정 파일 수정 실패"
    exit 1
  }

# User-specific environment variables
export USER_DATA="$USER_DATA"
export CONDA_ENVS_PATH="$USER_DATA/.conda/envs"
export CONDARC="$USER_DATA/.condarc"
EOF
  chown "$USERNAME:$GROUPNAME" "$SHELL_RC"
fi

# .local/bin 생성
if [ ! -d "$USER_DATA/.local/bin" ]; then
  mkdir -p "$USER_DATA/.local/bin" || {
    echo "[ERROR] .local/bin 디렉토리 생성 실패"
    exit 1
  }
  chown -R "$USERNAME:$GROUPNAME" "$USER_DATA/.local"
fi

echo "[INFO] 사용자 $USERNAME Conda 환경 설정 완료"