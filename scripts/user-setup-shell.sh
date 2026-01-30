#!/bin/bash
# [04-1] 사용자 쉘 환경 설정
# 역할: 신규 사용자의 쉘 환경 설정 (bash/zsh 선택, oh-my-zsh 설치)

set -e

USERNAME=$1
SHELL_CHOICE=${2:-bash}
GROUPNAME=${3:-gpu-users}

USER_HOME="/home/$USERNAME"
USER_DATA="/data/users/$USERNAME"
USER_DOTFILES="$USER_DATA/dotfiles"
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config"

# Root 권한 확인
if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 <username> [bash|zsh-minimal|zsh-full|zsh-pure] [groupname]"
  exit 1
fi

# 입력 검증
if [ -z "$USERNAME" ]; then
  echo "[ERROR] 사용법: sudo $0 <username> [bash|zsh-minimal|zsh-full|zsh-pure] [groupname]"
  exit 1
fi

if [ ! -d "$USER_DATA" ]; then
  echo "[ERROR] 사용자 데이터 디렉토리가 없습니다: $USER_DATA"
  exit 1
fi

if [ ! -f "$CONFIG_DIR/.hpcrc" ]; then
  echo "[ERROR] 설정 파일이 없습니다: $CONFIG_DIR/.hpcrc"
  exit 1
fi

# 유효한 쉘 선택 검증
case "$SHELL_CHOICE" in
  bash|zsh-minimal|zsh-full|zsh-pure)
    ;;
  *)
    echo "[ERROR] 유효하지 않은 쉘 선택: $SHELL_CHOICE"
    echo "[ERROR] 선택 가능: bash, zsh-minimal, zsh-full, zsh-pure"
    exit 1
    ;;
esac

# Helper: zsh 설치 (필요한 경우)
install_zsh_if_needed() {
  if ! command -v zsh &> /dev/null; then
    echo "[INFO] zsh 설치 중..."
    apt-get update -qq
    apt-get install -y zsh git curl &> /dev/null || {
      echo "[ERROR] zsh 설치 실패"
      exit 1
    }
    echo "[INFO] zsh 설치 완료"
  else
    echo "[INFO] zsh이 이미 설치되어 있습니다"
  fi
}

install_oh_my_zsh() {
  local omz_dir="$USER_DOTFILES/.oh-my-zsh"
  
  if [ -d "$omz_dir" ]; then
    echo "[INFO] oh-my-zsh이 이미 설치되어 있습니다"
    return 0
  fi
  
  echo "[INFO] oh-my-zsh 설치 중..."
  mkdir -p "$USER_DOTFILES"
  
  export ZSH="$omz_dir"
  sudo -u "$USERNAME" ZSH="$omz_dir" sh -c 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' 2>/dev/null || {
    echo "[ERROR] oh-my-zsh 설치 실패"
    exit 1
  }
  
  chmod -R go-w "$omz_dir"
  chown -R "$USERNAME:$GROUPNAME" "$omz_dir"
  
  if [ -f "$ZSHRC" ] && ! grep -q "ZSH_DISABLE_COMPFIX" "$ZSHRC"; then
    sed -i '1i export ZSH_DISABLE_COMPFIX="true"' "$ZSHRC"
    chown "$USERNAME:$GROUPNAME" "$ZSHRC"
  fi
  
  if [ ! -L "$USER_HOME/.oh-my-zsh" ]; then
    ln -sf "$omz_dir" "$USER_HOME/.oh-my-zsh"
    echo "[INFO] ~/.oh-my-zsh 심볼릭 링크 생성"
  fi
  
  echo "[INFO] oh-my-zsh 설치 완료: $omz_dir"
}

install_zsh_plugins() {
  local custom_dir="$USER_DOTFILES/.oh-my-zsh/custom/plugins"
  
  echo "[INFO] zsh 플러그인 설치 중..."
  
  # zsh-autosuggestions
  if [ ! -d "$custom_dir/zsh-autosuggestions" ]; then
    sudo -u "$USERNAME" git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/zsh-autosuggestions" 2>/dev/null || {
      echo "[WARNING] zsh-autosuggestions 설치 실패"
    }
  fi
  
  # zsh-syntax-highlighting
  if [ ! -d "$custom_dir/zsh-syntax-highlighting" ]; then
    sudo -u "$USERNAME" git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom_dir/zsh-syntax-highlighting" 2>/dev/null || {
      echo "[WARNING] zsh-syntax-highlighting 설치 실패"
    }
  fi
  
  chmod -R go-w "$custom_dir"
  chown -R "$USERNAME:$GROUPNAME" "$custom_dir"
  
  echo "[INFO] zsh 플러그인 설치 완료"
}

# Helper: .zshrc 설정 (플러그인 활성화)
configure_zshrc() {
  if [ ! -f "$ZSHRC" ]; then
    echo "[ERROR] .zshrc 파일이 없습니다: $ZSHRC"
    exit 1
  fi
  
  # 플러그인 설정 (기존 plugins 라인 찾아서 수정)
  if grep -q "^plugins=" "$ZSHRC"; then
    # 기존 plugins 라인 수정
    sudo -u "$USERNAME" sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
  else
    # plugins 라인 추가
    sudo -u "$USERNAME" sed -i '/^ZSH=/a plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' "$ZSHRC"
  fi
  
  chown "$USERNAME:$GROUPNAME" "$ZSHRC"
  echo "[INFO] .zshrc 플러그인 설정 완료"
}

copy_hpcrc() {
  local target_hpcrc="$USER_DOTFILES/.hpcrc"
  
  mkdir -p "$USER_DOTFILES"
  chown "$USERNAME:$GROUPNAME" "$USER_DOTFILES"
  
  if [ ! -f "$target_hpcrc" ]; then
    cp "$CONFIG_DIR/.hpcrc" "$target_hpcrc" || {
      echo "[ERROR] .hpcrc 복사 실패"
      exit 1
    }
    chown "$USERNAME:$GROUPNAME" "$target_hpcrc"
    echo "[INFO] .hpcrc 복사 완료: $target_hpcrc"
  else
    echo "[INFO] .hpcrc이 이미 존재합니다"
  fi
}

# Helper: 쉘 rc 파일에 .hpcrc 소스 추가
add_source_hpcrc() {
  local shell_rc=$1
  
  if [ ! -f "$shell_rc" ]; then
    echo "[ERROR] 쉘 rc 파일이 없습니다: $shell_rc"
    exit 1
  fi
  
  # 이미 source ~/.hpcrc가 있는지 확인
  if ! grep -q "source.*\.hpcrc" "$shell_rc"; then
    echo "" >> "$shell_rc"
    echo "# Source .hpcrc for aliases and settings" >> "$shell_rc"
    echo "[ -f ~/.hpcrc ] && source ~/.hpcrc" >> "$shell_rc"
    echo "[INFO] .hpcrc 소스 추가 완료"
  else
    echo "[INFO] .hpcrc 소스가 이미 설정되어 있습니다"
  fi
  
  chown "$USERNAME:$GROUPNAME" "$shell_rc"
}

# Helper: 사용자 기본 쉘 변경
change_user_shell() {
  local new_shell=$1
  
  if ! command -v "$new_shell" &> /dev/null; then
    echo "[ERROR] 쉘을 찾을 수 없습니다: $new_shell"
    exit 1
  fi
  
  local shell_path=$(command -v "$new_shell")
  chsh -s "$shell_path" "$USERNAME" || {
    echo "[ERROR] 쉘 변경 실패: $new_shell"
    exit 1
  }
  
  echo "[INFO] 사용자 $USERNAME의 기본 쉘을 $new_shell로 변경했습니다"
}

# ============================================================================
# Main Logic
# ============================================================================

echo "[INFO] 사용자 $USERNAME의 쉘 환경 설정 시작 (선택: $SHELL_CHOICE)"

# .hpcrc 복사 (모든 경우)
copy_hpcrc

BASHRC="$USER_DOTFILES/.bashrc"
ZSHRC="$USER_DOTFILES/.zshrc"

case "$SHELL_CHOICE" in
  bash)
    echo "[INFO] bash 환경 설정 중..."
    if [ ! -f "$BASHRC" ]; then
      echo "[ERROR] .bashrc 파일이 없습니다: $BASHRC"
      exit 1
    fi
    add_source_hpcrc "$BASHRC"
    echo "[INFO] bash 환경 설정 완료"
    ;;
    
  zsh-minimal)
    echo "[INFO] zsh-minimal 환경 설정 중..."
    install_zsh_if_needed
    install_oh_my_zsh
    if grep -q "^plugins=" "$ZSHRC"; then
      sudo -u "$USERNAME" sed -i 's/^plugins=.*/plugins=(git)/' "$ZSHRC"
    else
      sudo -u "$USERNAME" sed -i '/^ZSH=/a plugins=(git)' "$ZSHRC"
    fi
    chown "$USERNAME:$GROUPNAME" "$ZSHRC"
    add_source_hpcrc "$ZSHRC"
    change_user_shell "zsh"
    echo "[INFO] zsh-minimal 환경 설정 완료"
    ;;
    
  zsh-full)
    echo "[INFO] zsh-full 환경 설정 중..."
    install_zsh_if_needed
    install_oh_my_zsh
    install_zsh_plugins
    configure_zshrc
    add_source_hpcrc "$ZSHRC"
    change_user_shell "zsh"
    echo "[INFO] zsh-full 환경 설정 완료"
    ;;
    
  zsh-pure)
    echo "[INFO] zsh-pure 환경 설정 중..."
    install_zsh_if_needed
    if [ ! -f "$ZSHRC" ]; then
      sudo -u "$USERNAME" touch "$ZSHRC"
    fi
    chown "$USERNAME:$GROUPNAME" "$ZSHRC"
    add_source_hpcrc "$ZSHRC"
    change_user_shell "zsh"
    echo "[INFO] zsh-pure 환경 설정 완료"
    ;;
esac

echo "[INFO] 사용자 $USERNAME의 쉘 환경 설정 완료"
