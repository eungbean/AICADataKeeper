#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$SCRIPT_DIR/scripts"
VERSION="2.0.0"

# ═══════════════════════════════════════════════════════════════════════════════
# Theme (opencode OC-1 dark inspired)
# ═══════════════════════════════════════════════════════════════════════════════
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'

C_PRIMARY='\033[38;5;216m'    # peach/orange #fab283 (OC-1 primary)
C_BLUE='\033[38;5;33m'        # interactive blue #034cff
C_TEXT='\033[38;5;252m'       # light gray (smoke-dark-11)
C_MUTED='\033[38;5;245m'      # mid gray for text
C_BOX='\033[38;5;239m'        # dark gray for box borders
C_SUCCESS='\033[38;5;40m'     # bright green #12c905
C_WARNING='\033[38;5;220m'    # yellow #fcd53a
C_ERROR='\033[38;5;203m'      # red-orange #fc533a

C_BG_BOX='\033[48;5;236m'     # gray box background
C_BG_SELECT='\033[48;5;238m'  # selection background

# ═══════════════════════════════════════════════════════════════════════════════
# UI Components
# ═══════════════════════════════════════════════════════════════════════════════
ui_header() {
  clear
  echo ""
  echo -e "  ${C_PRIMARY}${C_BOLD}AICADataKeeper${C_RESET} ${C_MUTED}v${VERSION}${C_RESET}"
  echo -e "  ${C_MUTED}GPU 서버 환경 관리 시스템${C_RESET}"
  echo ""
}

ui_title() {
  echo -e "  ${C_TEXT}${C_BOLD}$1${C_RESET}"
  echo ""
}

ui_subtitle() {
  echo -e "  ${C_MUTED}$1${C_RESET}"
}

ui_divider() {
  echo -e "  ${C_BOX}─────────────────────────────────────────────────${C_RESET}"
}

ui_box_top() {
  echo -e "  ${C_BOX}┌─────────────────────────────────────────────────┐${C_RESET}"
}

ui_box_mid() {
  echo -e "  ${C_BOX}├─────────────────────────────────────────────────┤${C_RESET}"
}

ui_box_bottom() {
  echo -e "  ${C_BOX}└─────────────────────────────────────────────────────┘${C_RESET}"
}

ui_box_line() {
  local content="$1"
  local len=${#content}
  local pad=$((47 - len))
  local spaces=""
  for ((i=0; i<pad; i++)); do spaces+=" "; done
  echo -e "  ${C_BOX}│${C_RESET} $content$spaces ${C_BOX}│${C_RESET}"
}

ui_success() {
  echo -e "  ${C_SUCCESS}✓${C_RESET} ${C_TEXT}$1${C_RESET}"
}

ui_error() {
  echo -e "  ${C_ERROR}✗${C_RESET} ${C_TEXT}$1${C_RESET}"
}

ui_info() {
  echo -e "  ${C_MUTED}→${C_RESET} ${C_MUTED}$1${C_RESET}"
}

ui_warn() {
  echo -e "  ${C_WARNING}!${C_RESET} ${C_TEXT}$1${C_RESET}"
}

ui_step() {
  echo -e "  ${C_PRIMARY}[$1]${C_RESET} ${C_TEXT}$2${C_RESET}"
}

ui_keyhint() {
  echo -e "  ${C_MUTED}$1${C_RESET} ${C_DIM}$2${C_RESET}"
}

ui_selected() {
  echo -e "  ${C_BG_SELECT}${C_PRIMARY} ● ${C_TEXT}${C_BOLD}$1${C_RESET}${C_BG_SELECT} ${C_RESET}"
}

ui_option() {
  if [ "$2" = "on" ]; then
    echo -e "    ${C_SUCCESS}●${C_RESET} ${C_TEXT}$1${C_RESET}"
  else
    echo -e "    ${C_MUTED}○${C_RESET} ${C_MUTED}$1${C_RESET}"
  fi
}

ui_menu_item() {
  local num="$1"
  local label="$2"
  local desc="$3"
  echo -e "    ${C_PRIMARY}${num}${C_RESET}  ${C_TEXT}${label}${C_RESET}  ${C_MUTED}${desc}${C_RESET}"
}

ui_prompt() {
  echo -ne "  ${C_MUTED}›${C_RESET} "
}

ui_wait() {
  echo ""
  echo -ne "  ${C_MUTED}계속하려면 Enter...${C_RESET}"
  read -r
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dialog/Whiptail detection
# ═══════════════════════════════════════════════════════════════════════════════
if command -v dialog &> /dev/null; then
  DIALOG_CMD="dialog"
elif command -v whiptail &> /dev/null; then
  DIALOG_CMD="whiptail"
else
  echo "[ERROR] dialog 또는 whiptail이 필요합니다."
  echo "[ERROR] 설치: sudo apt install dialog"
  exit 1
fi

TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# ═══════════════════════════════════════════════════════════════════════════════
# Admin Functions
# ═══════════════════════════════════════════════════════════════════════════════

admin_initial_setup() {
  local GROUPNAME="gpu-users"
  local CHOICES=""
  
  CHOICES=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
      --title " 초기 설정 " \
      --item-help \
      --checklist "\n설치할 항목을 선택하세요:\n\n↑↓ 이동 | Space 선택 | Enter 확인" 18 70 6 \
      "GROUP" "공유 그룹 생성" on \
        "입력한 이름으로 새 그룹 생성" \
      "ADMIN" "관리자 계정 설정" on \
        "관리자 계정(기본: ubuntu)을 그룹에 추가하고 환경 설정" \
      "STORAGE" "저장소 권한 할당" on \
        "/data, /backup에 그룹 소유권 할당 (2775 setgid)" \
      "FOLDERS" "폴더 구조 생성" on \
        "users, models, cache, apps, config 등 필수 디렉토리 생성" \
      "ENV" "개발환경 설정" on \
        "Miniconda, uv, 환경변수 설정 (세부 설정 가능)" \
      "SUDOERS" "sudoers 설정" on \
        "일반 사용자가 캐시 정리, 디스크 확인을 sudo 없이 실행 가능하게 설정" \
      3>&1 1>&2 2>&3)
    
    [ $? -ne 0 ] && return
    
    if [ -z "$CHOICES" ]; then
      $DIALOG_CMD --clear --msgbox "선택된 항목이 없습니다." 7 30
      return
    fi
    
    local ENV_CHOICES=""
    if echo "$CHOICES" | grep -q "ENV"; then
      ENV_CHOICES=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
        --title " 개발환경 설정 " \
        --item-help \
        --checklist "\n설치할 항목을 선택하세요:" 14 78 3 \
        "CONDA" "Miniconda 설치" on \
          "/data/apps/miniconda3 설치 + 공유 패키지 캐시 /data/cache/conda/pkgs" \
        "UV" "uv 설치 (pip 대체, 10-100배 빠름)" on \
          "uv pip install pkg 형태로 사용. 캐시는 개인 ~/.cache/uv 사용" \
        "ENVVARS" "환경변수 설정 (HF/Torch 모델 공유)" on \
          "HuggingFace, PyTorch 모델 공유 경로 설정 (/data/models)" \
        3>&1 1>&2 2>&3)
      [ $? -ne 0 ] && return
    fi
    
    local NEW_GROUPNAME=""
    if echo "$CHOICES" | grep -q "GROUP"; then
      NEW_GROUPNAME=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
        --title " 그룹 생성 " \
        --inputbox "\n생성할 그룹명 (예: gpu-users):" 10 50 "" \
        3>&1 1>&2 2>&3)
      [ $? -ne 0 ] && return
      if [ -z "$NEW_GROUPNAME" ]; then
        $DIALOG_CMD --clear --msgbox "그룹명을 입력하세요." 7 30
        return
      fi
    fi
    
    local ADMIN_USER=""
    if echo "$CHOICES" | grep -q "ADMIN"; then
      ADMIN_USER=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
        --title " 관리자 계정 " \
        --inputbox "\n관리자 계정명 (예: ubuntu):" 10 50 "" \
        3>&1 1>&2 2>&3)
      [ $? -ne 0 ] && return
      if [ -z "$ADMIN_USER" ]; then
        $DIALOG_CMD --clear --msgbox "관리자 계정명을 입력하세요." 7 35
        return
      fi
    fi
    
    if echo "$CHOICES" | grep -qE "ADMIN|STORAGE|FOLDERS|ENV"; then
      local GROUP_LIST=$(getent group | cut -d: -f1 | grep -vE "^(root|daemon|bin|sys|adm|tty|disk|lp|mail|news|uucp|man|proxy|kmem|dialout|fax|voice|cdrom|floppy|tape|sudo|audio|dip|www-data|backup|operator|list|irc|src|gnats|shadow|utmp|video|sasl|plugdev|staff|games|users|nogroup|systemd|netdev|crontab|messagebus|input|kvm|render|sgx|_ssh|lxd|docker|rdma|ntp|ssl-cert|syslog|uuidd)$" | sort)
      
      local -a MENU_ITEMS=()
      if [ -n "$NEW_GROUPNAME" ]; then
        MENU_ITEMS+=("$NEW_GROUPNAME" "$NEW_GROUPNAME (새로 생성)" "on")
      fi
      
      for g in $GROUP_LIST; do
        if [ ${#MENU_ITEMS[@]} -eq 0 ]; then
          MENU_ITEMS+=("$g" "$g" "on")
        else
          MENU_ITEMS+=("$g" "$g" "off")
        fi
      done
      
      if [ ${#MENU_ITEMS[@]} -eq 0 ]; then
        $DIALOG_CMD --clear --msgbox "사용 가능한 그룹이 없습니다.\n먼저 '공유 그룹 생성'을 선택하세요." 8 45
        return
      fi
      
      GROUPNAME=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
        --title " 그룹 선택 " \
        --radiolist "\n권한을 할당할 그룹 선택:" 15 50 6 \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3)
      [ $? -ne 0 ] && return
      
      if [ -z "$GROUPNAME" ]; then
        $DIALOG_CMD --clear --msgbox "그룹을 선택하세요." 7 30
        return
      fi
    fi
    
    if [ -n "$NEW_GROUPNAME" ]; then
      GROUPNAME=${GROUPNAME:-$NEW_GROUPNAME}
    fi
    
    local LOG_FILE=$(mktemp)
    
    _run_initial_setup "$GROUPNAME" "$CHOICES" "$ENV_CHOICES" "$NEW_GROUPNAME" "$ADMIN_USER" 2>&1 | \
      sed -u 's/\x1b\[[0-9;]*m//g' | \
      tee "$LOG_FILE" | \
      $DIALOG_CMD --clear --title " 설정 진행 중... " --progressbox 20 65 || true
    
    local SUMMARY="\n"
    while IFS= read -r line; do
      if [[ "$line" == *"✓"* ]]; then
        line="${line//✓/\\Z2\\Zb✓\\ZB\\Zn}"
        SUMMARY+="$line\n"
      elif [[ "$line" == *"✗"* ]]; then
        line="${line//✗/\\Z1\\Zb✗\\ZB\\Zn}"
        SUMMARY+="$line\n"
      elif [[ "$line" == *"!"* ]]; then
        line="${line//!/\\Z3\\Zb!\\ZB\\Zn}"
        SUMMARY+="$line\n"
      elif [[ "$line" == *"→"* ]]; then
        line="${line//→/\\Z4→\\Zn}"
        SUMMARY+="$line\n"
      fi
    done < "$LOG_FILE"
    
    local LINE_COUNT=$(echo -e "$SUMMARY" | wc -l)
    local HEIGHT=$((LINE_COUNT + 4))
    [ $HEIGHT -lt 10 ] && HEIGHT=10
    [ $HEIGHT -gt 22 ] && HEIGHT=22
    
    $DIALOG_CMD --colors --clear --title " 설정 완료 " --msgbox "$SUMMARY" $HEIGHT 62
    
    local NEXT_MSG="\n\Zb[다음 단계]\ZB 터미널에서 아래 명령어를 실행 후\n           이 프로그램을 다시 실행해주세요:\n"
    if [ -n "$ADMIN_USER" ]; then
      NEXT_MSG+="\n  \Zb0.\ZB 관리자 계정으로 로그인:\n     \Z4su - $ADMIN_USER\Zn\n"
    fi
    NEXT_MSG+="\n  \Zb1.\ZB 그룹 멤버십 적용:\n     \Z4newgrp $GROUPNAME\Zn\n"
    NEXT_MSG+="\n  \Zb2.\ZB 공유 권한 설정 \Z1(필수)\Zn:\n     \Z4echo \"umask 002\" >> ~/.bashrc\n     source ~/.bashrc\Zn\n"
    NEXT_MSG+="\n\Z3※ 위 명령어는 초기 설정 후 한 번만 실행\Zn"
    
    $DIALOG_CMD --colors --clear --title " 다음 단계 안내 " --msgbox "$NEXT_MSG" 20 55
    rm -f "$LOG_FILE"
}

_run_initial_setup() {
  local GROUPNAME="$1"
  local CHOICES="$2"
  local ENV_CHOICES="$3"
  local NEW_GROUPNAME="$4"
  local ADMIN_USER="$5"
  local DATA_OWNER="${ADMIN_USER:-root}"
  
  _print_plan() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  설치 계획:"
    echo "$CHOICES" | grep -q "GROUP" && echo "  [ ] 1. 그룹 생성" || echo "  [-] 1. 그룹 생성 (건너뜀)"
    echo "$CHOICES" | grep -q "ADMIN" && echo "  [ ] 2. 관리자 계정" || echo "  [-] 2. 관리자 계정 (건너뜀)"
    echo "$CHOICES" | grep -q "STORAGE" && echo "  [ ] 3. 저장소 권한" || echo "  [-] 3. 저장소 권한 (건너뜀)"
    echo "$CHOICES" | grep -q "FOLDERS" && echo "  [ ] 4. 폴더 구조" || echo "  [-] 4. 폴더 구조 (건너뜀)"
    echo "$CHOICES" | grep -q "ENV" && echo "  [ ] 5. 개발환경" || echo "  [-] 5. 개발환경 (건너뜀)"
    echo "$CHOICES" | grep -q "SUDOERS" && echo "  [ ] 6. sudoers" || echo "  [-] 6. sudoers (건너뜀)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  }
  
  _print_plan
  
  if echo "$CHOICES" | grep -q "GROUP"; then
    ui_step "1/6" "그룹 생성 중..."
    local CREATE_GROUP="${NEW_GROUPNAME:-$GROUPNAME}"
    if getent group "$CREATE_GROUP" > /dev/null 2>&1; then
      ui_info "그룹 '$CREATE_GROUP' 이미 존재"
    else
      if groupadd "$CREATE_GROUP" 2>/dev/null; then
        ui_success "그룹 '$CREATE_GROUP' 생성됨"
      else
        ui_error "그룹 '$CREATE_GROUP' 생성 실패"
      fi
    fi
    echo ""
  fi
  
  if echo "$CHOICES" | grep -q "ADMIN"; then
    ui_step "2/6" "관리자 계정 설정 중..."
    if [ -n "$ADMIN_USER" ]; then
      if id "$ADMIN_USER" &>/dev/null; then
        ui_info "사용자 '$ADMIN_USER' 존재 확인"
        if usermod -aG "$GROUPNAME" "$ADMIN_USER" 2>/dev/null; then
          ui_success "'$ADMIN_USER' → '$GROUPNAME' 그룹 추가됨"
        else
          ui_error "'$ADMIN_USER' 그룹 추가 실패"
        fi
        if [ -f "$SCRIPTS_PATH/user-setup.sh" ]; then
          if "$SCRIPTS_PATH/user-setup.sh" "$ADMIN_USER" "$GROUPNAME" > /dev/null 2>&1; then
            ui_success "'$ADMIN_USER' 환경 설정 완료"
          else
            ui_error "'$ADMIN_USER' 환경 설정 실패"
          fi
        fi
        if [ -f "$SCRIPTS_PATH/user-register.sh" ]; then
          "$SCRIPTS_PATH/user-register.sh" "$ADMIN_USER" "$GROUPNAME" > /dev/null 2>&1 || true
          ui_success "'$ADMIN_USER' 자동복구 등록됨"
        fi
      else
        ui_error "사용자 '$ADMIN_USER' 존재하지 않음"
      fi
    fi
    echo ""
  fi
  
  if echo "$CHOICES" | grep -q "STORAGE"; then
    ui_step "3/6" "저장소 권한 할당 중..."
    if [ -d /data ]; then
      if chown "$DATA_OWNER":"$GROUPNAME" /data 2>/dev/null && chmod 2775 /data 2>/dev/null; then
        ui_success "/data → $DATA_OWNER:$GROUPNAME (2775)"
      else
        ui_error "/data 권한 설정 실패 (그룹 '$GROUPNAME' 확인)"
      fi
    else
      ui_warn "/data 디렉토리 없음"
    fi
    if [ -d /backup ]; then
      if chown "$DATA_OWNER":"$GROUPNAME" /backup 2>/dev/null && chmod 2775 /backup 2>/dev/null; then
        ui_success "/backup → $DATA_OWNER:$GROUPNAME (2775)"
      else
        ui_error "/backup 권한 설정 실패"
      fi
    else
      ui_info "/backup 없음, 건너뜀"
    fi
    echo ""
  fi
  
  if echo "$CHOICES" | grep -q "FOLDERS"; then
    ui_step "4/6" "폴더 구조 생성 중..."
    local FOLDERS=(
      "/data/users"
      "/data/models/huggingface/hub"
      "/data/models/huggingface/datasets"
      "/data/models/torch"
      "/data/cache/conda/pkgs"
      "/data/apps"
      "/data/config"
      "/data/dataset"
      "/data/code"
    )
    for dir in "${FOLDERS[@]}"; do
      if [ -d "$dir" ]; then
        ui_info "$dir 이미 존재"
      else
        if mkdir -p "$dir" 2>/dev/null; then
          ui_success "$dir 생성됨"
        else
          ui_error "$dir 생성 실패"
        fi
      fi
      chown root:"$GROUPNAME" "$dir" 2>/dev/null || true
      chmod 2775 "$dir" 2>/dev/null || true
    done
    echo ""
  fi
  
  if echo "$CHOICES" | grep -q "ENV"; then
    ui_step "5/6" "개발환경 설정 중..."
    
    if echo "$ENV_CHOICES" | grep -q "CONDA"; then
      ui_info "Miniconda 설치..."
      if [ -d /data/apps/miniconda3 ]; then
        ui_info "  이미 설치됨"
      else
        if [ -f "$SCRIPTS_PATH/install-miniconda.sh" ]; then
          if "$SCRIPTS_PATH/install-miniconda.sh" /data/apps/miniconda3 > /dev/null 2>&1; then
            ui_success "  Miniconda 설치 완료"
          else
            ui_error "  Miniconda 설치 실패"
          fi
        else
          ui_error "  install-miniconda.sh 없음"
        fi
      fi
      mkdir -p /data/cache/conda/pkgs 2>/dev/null || true
      chown root:"$GROUPNAME" /data/cache/conda/pkgs 2>/dev/null || true
      chmod 2775 /data/cache/conda/pkgs 2>/dev/null || true
      ui_success "  conda 캐시 설정됨"
    fi
    
    if echo "$ENV_CHOICES" | grep -q "UV"; then
      ui_info "uv 설치..."
      if [ -f "$SCRIPTS_PATH/install-uv.sh" ]; then
        if "$SCRIPTS_PATH/install-uv.sh" > /dev/null 2>&1; then
          ui_success "  uv 설치 완료"
        else
          ui_error "  uv 설치 실패"
        fi
      else
        ui_error "  install-uv.sh 없음"
      fi
      ui_info "  uv 캐시: ~/.cache/uv (개인)"
    fi
    
    if echo "$ENV_CHOICES" | grep -q "ENVVARS"; then
      ui_info "환경 변수 설정..."
      if [ -f /etc/profile.d/global_envs.sh ]; then
        ui_info "  이미 존재"
      else
        if [ -f "$SCRIPTS_PATH/install-global-env.sh" ]; then
          if "$SCRIPTS_PATH/install-global-env.sh" "$GROUPNAME" > /dev/null 2>&1; then
            ui_success "  전역 환경 설정 완료"
          else
            ui_error "  전역 환경 설정 실패"
          fi
        else
          ui_error "  install-global-env.sh 없음"
        fi
      fi
    fi
    echo ""
  fi
  
  if echo "$CHOICES" | grep -q "SUDOERS"; then
    ui_step "6/6" "sudoers 설정 중..."
    if [ -f "$SCRIPTS_PATH/system-sudoers.sh" ]; then
      if "$SCRIPTS_PATH/system-sudoers.sh" > /dev/null 2>&1; then
        ui_success "sudoers 설정 완료"
      else
        ui_error "sudoers 설정 실패"
      fi
    else
      ui_warn "system-sudoers.sh 없음"
    fi
    echo ""
  fi
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ui_success "설정 완료!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

admin_add_user() {
  ui_header
  ui_title "사용자 추가"
  ui_subtitle "새 사용자 계정 생성 및 환경 설정"
  echo ""
  
  echo -ne "  ${C_MUTED}사용자명${C_RESET}: "
  read -r USERNAME
  if [ -z "$USERNAME" ]; then
    ui_error "사용자명을 입력하세요"
    ui_wait
    return 1
  fi
  
  if id "$USERNAME" &>/dev/null; then
    ui_warn "사용자 '$USERNAME' 이미 존재"
    echo -ne "  ${C_MUTED}환경 설정만 진행할까요? [y/N]${C_RESET}: "
    read -r CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
      return 0
    fi
  else
    ui_info "사용자 생성 중..."
    adduser "$USERNAME" || {
      ui_error "사용자 생성 실패"
      ui_wait
      return 1
    }
    ui_success "사용자 '$USERNAME' 생성됨"
  fi
  
  echo ""
  echo -ne "  ${C_MUTED}그룹명 ${C_DIM}(gpu-users)${C_RESET}: "
  read -r GROUPNAME
  GROUPNAME=${GROUPNAME:-gpu-users}
  
  ui_info "그룹에 추가 중..."
  usermod -aG "$GROUPNAME" "$USERNAME"
  ui_success "그룹 '$GROUPNAME'에 추가됨"
  
  echo ""
  ui_divider
  echo ""
  ui_title "SSH 키 설정"
  echo ""
  ui_menu_item "1" "공개키 붙여넣기" "기존 키 사용"
  ui_menu_item "2" "새 키 쌍 생성" "새로 생성"
  ui_menu_item "3" "건너뛰기" "나중에 설정"
  echo ""
  ui_prompt
  read -r SSH_CHOICE
  
  USER_HOME="/data/users/$USERNAME"
  SSH_DIR="$USER_HOME/.ssh"
  
  case $SSH_CHOICE in
    1)
      echo ""
      ui_info "공개키를 붙여넣으세요 (Enter 후 Ctrl+D):"
      mkdir -p "$SSH_DIR"
      cat > "$SSH_DIR/authorized_keys"
      chmod 700 "$SSH_DIR"
      chmod 600 "$SSH_DIR/authorized_keys"
      chown -R "$USERNAME:$GROUPNAME" "$SSH_DIR"
      ui_success "SSH 공개키 등록됨"
      ;;
    2)
      echo ""
      echo -ne "  ${C_MUTED}키 타입 ${C_DIM}(ed25519)${C_RESET}: "
      read -r KEY_TYPE
      KEY_TYPE=${KEY_TYPE:-ed25519}
      
      mkdir -p "$SSH_DIR"
      ssh-keygen -t "$KEY_TYPE" -f "$SSH_DIR/id_$KEY_TYPE" -N "" -C "$USERNAME@aica"
      cat "$SSH_DIR/id_$KEY_TYPE.pub" >> "$SSH_DIR/authorized_keys"
      chmod 700 "$SSH_DIR"
      chmod 600 "$SSH_DIR/authorized_keys"
      chmod 600 "$SSH_DIR/id_$KEY_TYPE"
      chmod 644 "$SSH_DIR/id_$KEY_TYPE.pub"
      chown -R "$USERNAME:$GROUPNAME" "$SSH_DIR"
      
      echo ""
      ui_success "SSH 키 쌍 생성됨"
      ui_warn "개인키를 사용자에게 안전하게 전달하세요:"
      echo -e "    ${C_MUTED}$SSH_DIR/id_$KEY_TYPE${C_RESET}"
      echo ""
      echo -ne "  ${C_MUTED}개인키 출력? [y/N]${C_RESET}: "
      read -r SHOW_KEY
      if [ "$SHOW_KEY" = "y" ] || [ "$SHOW_KEY" = "Y" ]; then
        echo ""
        echo -e "  ${C_MUTED}────────── 개인키 ──────────${C_RESET}"
        cat "$SSH_DIR/id_$KEY_TYPE"
        echo -e "  ${C_MUTED}────────────────────────────${C_RESET}"
        echo ""
        ui_warn "이 키를 안전하게 보관하세요!"
      fi
      ;;
    3)
      ui_info "SSH 키 설정 건너뜀"
      ;;
    *)
      ui_info "SSH 키 설정 건너뜀"
      ;;
  esac
  
  echo ""
  ui_divider
  echo ""
  ui_info "사용자 환경 설정 중..."
  if [ -f "$SCRIPTS_PATH/user-setup.sh" ]; then
    "$SCRIPTS_PATH/user-setup.sh" "$USERNAME" "$GROUPNAME"
    ui_success "사용자 환경 설정 완료"
  else
    ui_error "user-setup.sh 없음"
    ui_wait
    return 1
  fi
  
  echo ""
  echo -ne "  ${C_MUTED}자동 복구 등록? [Y/n]${C_RESET}: "
  read -r REGISTER
  if [ "$REGISTER" != "n" ] && [ "$REGISTER" != "N" ]; then
    if [ -f "$SCRIPTS_PATH/user-register.sh" ]; then
      "$SCRIPTS_PATH/user-register.sh" "$USERNAME" "$GROUPNAME"
      ui_success "자동 복구 등록됨"
    fi
  fi
  
  echo ""
  ui_divider
  echo ""
  ui_success "사용자 '$USERNAME' 설정 완료!"
  echo ""
  ui_wait
}

admin_auto_recovery() {
  ui_header
  ui_title "자동 복구"
  ui_subtitle "systemd 복구 서비스 관리"
  echo ""
  ui_divider
  echo ""
  ui_menu_item "1" "활성화" "서비스 시작"
  ui_menu_item "2" "비활성화" "서비스 중지"
  ui_menu_item "3" "상태 확인" "서비스 상태"
  ui_menu_item "4" "수동 실행" "지금 복구 실행"
  ui_menu_item "q" "돌아가기" ""
  echo ""
  ui_prompt
  read -r RECOVERY_CHOICE
  
  echo ""
  case "$RECOVERY_CHOICE" in
    1)
      ui_info "복구 서비스 활성화 중..."
      if systemctl enable aica-recovery.service 2>/dev/null; then
        systemctl start aica-recovery.service 2>/dev/null || true
        ui_success "복구 서비스 활성화됨"
      else
        ui_error "aica-recovery.service 없음"
        ui_info "서비스 파일을 먼저 생성하세요"
      fi
      ;;
    2)
      ui_info "복구 서비스 비활성화 중..."
      if systemctl disable aica-recovery.service 2>/dev/null; then
        systemctl stop aica-recovery.service 2>/dev/null || true
        ui_success "복구 서비스 비활성화됨"
      else
        ui_warn "서비스 미설치"
      fi
      ;;
    3)
      ui_info "서비스 상태:"
      echo ""
      systemctl status aica-recovery.service 2>/dev/null || ui_warn "서비스 미설치"
      ;;
    4)
      ui_info "수동 복구 실행 중..."
      if [ -f "$SCRIPTS_PATH/ops-recovery.sh" ]; then
        "$SCRIPTS_PATH/ops-recovery.sh"
        ui_success "복구 완료"
      else
        ui_error "ops-recovery.sh 없음"
      fi
      ;;
    q|Q|5)
      return
      ;;
    *)
      ui_error "잘못된 선택"
      ;;
  esac
  
  ui_wait
}

_detect_test_params() {
  TEST_GROUP=""
  TEST_ADMIN=""
  
  # Try to read from users.txt
  if [ -f /data/config/users.txt ]; then
    while IFS=: read -r username groupname; do
      # Skip comments and empty lines
      [[ "$username" =~ ^#.*$ ]] && continue
      [ -z "$username" ] && continue
      
      # First non-comment, non-empty line
      TEST_ADMIN="$username"
      TEST_GROUP="$groupname"
      break
    done < /data/config/users.txt
  fi
  
  # Fallback: detect group from /data ownership
  if [ -z "$TEST_GROUP" ] && [ -d /data ]; then
    TEST_GROUP=$(stat -c %G /data 2>/dev/null || echo "")
  fi
  
  # Final fallback
  [ -z "$TEST_GROUP" ] && TEST_GROUP="gpu-users" || true
}

_run_setup_tests() {
  local GROUP="$1"
  local ADMIN="$2"
  
  PASS_COUNT=0
  FAIL_COUNT=0
  SKIP_COUNT=0
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  초기 설정 테스트"
  echo "  그룹: $GROUP | 관리자: ${ADMIN:-(없음)}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  ui_step "1/6" "그룹 생성"
  if getent group "$GROUP" > /dev/null 2>&1; then
    ui_success "그룹 '$GROUP' 존재"
    ((++PASS_COUNT)) || true
  else
    ui_error "그룹 '$GROUP' 없음"
    ((++FAIL_COUNT)) || true
  fi
  echo ""
  
  ui_step "2/6" "관리자 계정"
  if [ -z "$ADMIN" ]; then
    ui_warn "관리자 미등록 (건너뜀)"
    ((SKIP_COUNT += 4)) || true
  else
    if id "$ADMIN" &>/dev/null; then
      ui_success "사용자 '$ADMIN' 존재"
      ((++PASS_COUNT)) || true
    else
      ui_error "사용자 '$ADMIN' 없음"
      ((++FAIL_COUNT)) || true
    fi
    
    if id -nG "$ADMIN" 2>/dev/null | grep -qw "$GROUP"; then
      ui_success "'$GROUP' 그룹 멤버"
      ((++PASS_COUNT)) || true
    else
      ui_error "'$GROUP' 그룹 미포함"
      ((++FAIL_COUNT)) || true
    fi
    
    if [ -L "/home/$ADMIN" ] && [ "$(readlink "/home/$ADMIN")" = "/data/users/$ADMIN" ]; then
      ui_success "/home/$ADMIN → /data/users/$ADMIN"
      ((++PASS_COUNT)) || true
    else
      ui_error "/home/$ADMIN 심볼릭 링크 없음"
      ((++FAIL_COUNT)) || true
    fi
    
    if grep -q "^${ADMIN}:" /data/config/users.txt 2>/dev/null; then
      ui_success "users.txt 등록됨"
      ((++PASS_COUNT)) || true
    else
      ui_error "users.txt 미등록"
      ((++FAIL_COUNT)) || true
    fi
  fi
  echo ""
  
  ui_step "3/6" "저장소 권한"
  if [ -d /data ]; then
    ui_success "/data 디렉토리 존재"
    ((++PASS_COUNT)) || true
  else
    ui_error "/data 디렉토리 없음"
    ((++FAIL_COUNT)) || true
  fi
  
  if [ -d /data ] && [ "$(stat -c %G /data 2>/dev/null)" = "$GROUP" ]; then
    ui_success "/data 그룹 소유: $GROUP"
    ((++PASS_COUNT)) || true
  else
    ui_error "/data 그룹 소유 오류"
    ((++FAIL_COUNT)) || true
  fi
  
  if [ -d /data ] && stat -c %A /data 2>/dev/null | grep -q 's'; then
    ui_success "/data setgid (2775)"
    ((++PASS_COUNT)) || true
  else
    ui_error "/data setgid 미설정"
    ((++FAIL_COUNT)) || true
  fi
  
  if [ ! -d /backup ]; then
    ui_info "/backup 없음 (건너뜀)"
    ((SKIP_COUNT += 2)) || true
  else
    if [ "$(stat -c %G /backup 2>/dev/null)" = "$GROUP" ]; then
      ui_success "/backup 그룹 소유: $GROUP"
      ((++PASS_COUNT)) || true
    else
      ui_error "/backup 그룹 소유 오류"
      ((++FAIL_COUNT)) || true
    fi
    
    if stat -c %A /backup 2>/dev/null | grep -q 's'; then
      ui_success "/backup setgid (2775)"
      ((++PASS_COUNT)) || true
    else
      ui_error "/backup setgid 미설정"
      ((++FAIL_COUNT)) || true
    fi
  fi
  echo ""
  
  ui_step "4/6" "폴더 구조"
  local FOLDER_DIRS=(
    "/data/users"
    "/data/models/huggingface/hub"
    "/data/models/torch"
    "/data/cache/conda/pkgs"
    "/data/apps"
    "/data/config"
  )
  for dir in "${FOLDER_DIRS[@]}"; do
    if [ -d "$dir" ] && stat -c %A "$dir" 2>/dev/null | grep -q 's'; then
      ui_success "$dir (2775)"
      ((++PASS_COUNT)) || true
    else
      ui_error "$dir 없음/권한오류"
      ((++FAIL_COUNT)) || true
    fi
  done
  echo ""
  
  ui_step "5/6" "개발환경"
  if [ -x /data/apps/miniconda3/bin/conda ]; then
    ui_success "Miniconda 설치됨"
    ((++PASS_COUNT)) || true
  else
    ui_error "Miniconda 미설치"
    ((++FAIL_COUNT)) || true
  fi
  
  if command -v uv &>/dev/null || [ -x /usr/local/bin/uv ]; then
    ui_success "uv 설치됨"
    ((++PASS_COUNT)) || true
  else
    ui_error "uv 미설치"
    ((++FAIL_COUNT)) || true
  fi
  
  if [ -f /etc/profile.d/global_envs.sh ]; then
    ui_success "global_envs.sh 존재"
    ((++PASS_COUNT)) || true
  else
    ui_error "global_envs.sh 없음"
    ((++FAIL_COUNT)) || true
  fi
  
  if [ -d "/data/cache/conda/pkgs" ] && stat -c %A "/data/cache/conda/pkgs" 2>/dev/null | grep -q 's'; then
    ui_success "conda 공유 캐시 (2775)"
    ((++PASS_COUNT)) || true
  else
    ui_error "conda 공유 캐시 오류"
    ((++FAIL_COUNT)) || true
  fi
  
  if [ -d "/data/models/huggingface/hub" ] && stat -c %A "/data/models/huggingface/hub" 2>/dev/null | grep -q 's'; then
    ui_success "HuggingFace 모델 공유 (2775)"
    ((++PASS_COUNT)) || true
  else
    ui_error "HuggingFace 모델 공유 오류"
    ((++FAIL_COUNT)) || true
  fi
  
  ui_info "pip/uv 캐시: 개인 ~/.cache 사용"
  echo ""
  
  ui_step "6/6" "sudoers"
  if [ -f /etc/sudoers.d/aica-datakeeper ]; then
    ui_success "sudoers 파일 존재"
    ((++PASS_COUNT)) || true
  else
    ui_error "sudoers 파일 없음"
    ((++FAIL_COUNT)) || true
  fi
  
  if visudo -c -f /etc/sudoers.d/aica-datakeeper &>/dev/null; then
    ui_success "sudoers 문법 정상"
    ((++PASS_COUNT)) || true
  else
    ui_error "sudoers 문법 오류"
    ((++FAIL_COUNT)) || true
  fi
  echo ""
  
  ui_divider
  echo ""
  if [ "$FAIL_COUNT" -eq 0 ]; then
    ui_success "결과: $PASS_COUNT 통과, $SKIP_COUNT 건너뜀"
  else
    ui_warn "결과: $PASS_COUNT 통과, $FAIL_COUNT 실패, $SKIP_COUNT 건너뜀"
  fi
}

admin_test_config() {
  _detect_test_params
  
  local LOG_FILE=$(mktemp)
  
  _run_setup_tests "$TEST_GROUP" "$TEST_ADMIN" 2>&1 | \
    sed -u 's/\x1b\[[0-9;]*m//g' | \
    tee "$LOG_FILE" | \
    $DIALOG_CMD --clear --title " 초기 설정 테스트 " --progressbox 26 50 || true
  
  local SUMMARY="\n"
  while IFS= read -r line; do
    if [[ "$line" == *"✓"* ]]; then
      line="${line//✓/\\Z2\\Zb✓\\ZB\\Zn}"
      SUMMARY+="$line\n"
    elif [[ "$line" == *"✗"* ]]; then
      line="${line//✗/\\Z1\\Zb✗\\ZB\\Zn}"
      SUMMARY+="$line\n"
    elif [[ "$line" == *"⊘"* ]]; then
      line="${line//⊘/\\Z3\\Zb⊘\\ZB\\Zn}"
      SUMMARY+="$line\n"
    else
      SUMMARY+="$line\n"
    fi
  done < "$LOG_FILE"
  
  local LINE_COUNT=$(echo -e "$SUMMARY" | wc -l)
  local HEIGHT=$((LINE_COUNT + 4))
  [ $HEIGHT -lt 10 ] && HEIGHT=10
  [ $HEIGHT -gt 26 ] && HEIGHT=26
  
  $DIALOG_CMD --colors --clear --title " 테스트 결과 " --msgbox "$SUMMARY" $HEIGHT 52
  
  rm -f "$LOG_FILE"
}

show_admin_menu_dialog() {
  while true; do
    CHOICE=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
      --title " 관리자 메뉴 " \
      --menu "\n작업을 선택하세요:" 14 55 5 \
      1 "초기 설정" \
      2 "설정 테스트" \
      3 "사용자 추가" \
      4 "자동 복구" \
      q "종료" \
      3>&1 1>&2 2>&3)
    
    [ $? -ne 0 ] && { clear; exit 0; }
    
    case $CHOICE in
      1) admin_initial_setup ;;
      2) admin_test_config ;;
      3) admin_add_user ;;
      4) admin_auto_recovery ;;
      q) clear; exit 0 ;;
    esac
  done
}

# ============================================
# 사용자 메뉴 (일반 모드)
# ============================================

user_show_environment_info() {
  ui_header
  ui_title "환경 정보"
  echo ""
  
  echo -e "  ${C_MUTED}사용자${C_RESET}      $(whoami)"
  echo -e "  ${C_MUTED}그룹${C_RESET}        $(groups)"
  echo -e "  ${C_MUTED}홈${C_RESET}          $HOME"
  
  if [ -L "$HOME" ]; then
    echo -e "  ${C_MUTED}실제 경로${C_RESET}  $(readlink -f "$HOME")"
  fi
  
  echo ""
  ui_divider
  echo ""
  ui_subtitle "환경 변수"
  echo ""
  if [ -f /etc/profile.d/global_envs.sh ]; then
    source /etc/profile.d/global_envs.sh
    echo -e "  ${C_MUTED}PIP_CACHE_DIR${C_RESET}     $PIP_CACHE_DIR"
    echo -e "  ${C_MUTED}CONDA_PKGS_DIRS${C_RESET}   $CONDA_PKGS_DIRS"
    echo -e "  ${C_MUTED}UV_CACHE_DIR${C_RESET}      $UV_CACHE_DIR"
    echo -e "  ${C_MUTED}TORCH_HOME${C_RESET}        $TORCH_HOME"
    echo -e "  ${C_MUTED}HF_HOME${C_RESET}           $HF_HOME"
  else
    ui_warn "전역 환경 미설정"
  fi
  
  echo ""
  ui_divider
  echo ""
  ui_subtitle "Conda"
  echo ""
  if command -v conda &> /dev/null; then
    echo -e "  ${C_MUTED}버전${C_RESET}        $(conda --version 2>&1 | cut -d' ' -f2)"
    echo -e "  ${C_MUTED}활성 환경${C_RESET}  ${CONDA_DEFAULT_ENV:-base}"
    echo ""
    ui_info "내 환경 목록:"
    conda env list 2>/dev/null | grep -E "^[^#]" | while read -r line; do
      echo -e "    ${C_TEXT}$line${C_RESET}"
    done
  else
    ui_warn "Conda 미설치"
  fi
  
  ui_wait
}

user_show_disk_usage() {
  ui_header
  ui_title "디스크 사용량"
  echo ""
  
  if sudo -n df -h /data 2>/dev/null; then
    echo ""
    ui_subtitle "캐시 사용량"
    echo ""
    if [ -d /data/cache ]; then
      du -sh /data/cache/* 2>/dev/null | while read -r line; do
        echo -e "    ${C_TEXT}$line${C_RESET}"
      done
    fi
    
    echo ""
    ui_subtitle "내 홈 디렉토리"
    echo ""
    echo -e "    ${C_TEXT}$(du -sh "$HOME" 2>/dev/null)${C_RESET}"
  else
    ui_warn "디스크 정보 확인 권한 없음"
    ui_info "관리자에게 sudoers 설정을 요청하세요"
  fi
  
  ui_wait
}

user_clean_cache_menu() {
  ui_header
  ui_title "캐시 정리"
  ui_subtitle "공유 캐시 정리 (다른 사용자에게 영향 줄 수 있음)"
  echo ""
  ui_divider
  echo ""
  ui_menu_item "1" "Conda" "conda 패키지 캐시"
  ui_menu_item "2" "Pip" "pip 패키지 캐시"
  ui_menu_item "3" "PyTorch" "모델 캐시"
  ui_menu_item "4" "HuggingFace" "모델 캐시"
  ui_menu_item "5" "전체" "모든 캐시"
  ui_menu_item "q" "돌아가기" ""
  echo ""
  ui_prompt
  read -r choice
  
  echo ""
  case $choice in
    1)
      if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --conda 2>/dev/null; then
        ui_success "Conda 캐시 정리됨"
      else
        ui_error "캐시 정리 권한 없음"
      fi
      ;;
    2)
      if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --pip 2>/dev/null; then
        ui_success "Pip 캐시 정리됨"
      else
        ui_error "캐시 정리 권한 없음"
      fi
      ;;
    3)
      if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --torch 2>/dev/null; then
        ui_success "PyTorch 캐시 정리됨"
      else
        ui_error "캐시 정리 권한 없음"
      fi
      ;;
    4)
      if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --hf 2>/dev/null; then
        ui_success "HuggingFace 캐시 정리됨"
      else
        ui_error "캐시 정리 권한 없음"
      fi
      ;;
    5)
      echo -ne "  ${C_MUTED}정말 모든 캐시를 정리? [y/N]${C_RESET}: "
      read -r confirm
      if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --all 2>/dev/null; then
          ui_success "모든 캐시 정리됨"
        else
          ui_error "캐시 정리 권한 없음"
        fi
      else
        ui_info "취소됨"
      fi
      ;;
    q|Q|6)
      return
      ;;
    *)
      ui_error "잘못된 선택"
      ;;
  esac
  
  ui_wait
}

user_show_conda_guide() {
  ui_header
  ui_title "Conda 환경 관리 가이드"
  echo ""
  
  ui_subtitle "새 환경 생성"
  echo -e "    ${C_PRIMARY}conda create -n myenv python=3.10${C_RESET}"
  echo ""
  
  ui_subtitle "환경 활성화"
  echo -e "    ${C_PRIMARY}conda activate myenv${C_RESET}"
  echo ""
  
  ui_subtitle "패키지 설치"
  echo -e "    ${C_PRIMARY}conda install numpy pandas${C_RESET}"
  echo -e "    ${C_PRIMARY}pip install torch torchvision${C_RESET}"
  echo -e "    ${C_PRIMARY}uv pip install transformers${C_RESET}  ${C_MUTED}← 더 빠름${C_RESET}"
  echo ""
  
  ui_subtitle "환경 목록"
  echo -e "    ${C_PRIMARY}conda env list${C_RESET}"
  echo ""
  
  ui_subtitle "환경 삭제"
  echo -e "    ${C_PRIMARY}conda env remove -n myenv${C_RESET}"
  echo ""
  
  ui_divider
  echo ""
  ui_subtitle "주의사항"
  echo ""
  ui_info "패키지 캐시는 모든 사용자와 공유됩니다"
  ui_info "환경은 \$HOME/.conda/envs에 저장됩니다"
  ui_info "큰 모델 다운로드 시 다른 사용자에게 알려주세요"
  
  ui_wait
}

user_show_help() {
  ui_header
  ui_title "도움말"
  echo ""
  
  ui_subtitle "문제 해결"
  echo ""
  echo -e "  ${C_TEXT}Q: Conda 환경이 활성화되지 않아요${C_RESET}"
  echo -e "  ${C_MUTED}A: source ~/.bashrc 실행 후 다시 시도${C_RESET}"
  echo ""
  echo -e "  ${C_TEXT}Q: 패키지 설치가 Permission Denied로 실패해요${C_RESET}"
  echo -e "  ${C_MUTED}A: conda 환경 내에서 설치 (conda activate myenv)${C_RESET}"
  echo ""
  echo -e "  ${C_TEXT}Q: 디스크가 꽉 찼어요${C_RESET}"
  echo -e "  ${C_MUTED}A: 캐시 정리 메뉴에서 불필요한 캐시 정리${C_RESET}"
  echo ""
  
  ui_divider
  echo ""
  ui_subtitle "상세 문서"
  echo ""
  echo -e "  ${C_MUTED}docs/01-initial-setup.md${C_RESET}      초기 설정"
  echo -e "  ${C_MUTED}docs/02-user-management.md${C_RESET}   사용자 관리"
  echo -e "  ${C_MUTED}docs/03-environment.md${C_RESET}       환경 설정"
  echo -e "  ${C_MUTED}docs/04-maintenance.md${C_RESET}       유지보수"
  echo -e "  ${C_MUTED}docs/05-troubleshooting.md${C_RESET}   문제 해결"
  echo ""
  
  ui_divider
  echo ""
  ui_subtitle "관리자 문의"
  echo ""
  echo -e "  ${C_PRIMARY}eungbean@homilabs.ai${C_RESET}"
  
  ui_wait
}

show_user_menu_dialog() {
  while true; do
    CHOICE=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
      --title " 사용자 메뉴 " \
      --menu "\n작업을 선택하세요:" 15 55 6 \
      1 "환경 정보" \
      2 "디스크 사용량" \
      3 "캐시 정리" \
      4 "Conda 가이드" \
      5 "도움말" \
      q "종료" \
      3>&1 1>&2 2>&3)
    
    [ $? -ne 0 ] && { clear; exit 0; }
    
    case $CHOICE in
      1) user_show_environment_info ;;
      2) user_show_disk_usage ;;
      3) user_clean_cache_menu ;;
      4) user_show_conda_guide ;;
      5) user_show_help ;;
      q) clear; exit 0 ;;
    esac
  done
}

# ============================================
# 메인 실행
# ============================================

if [ "$1" == "--help" ]; then
  echo -e "${C_PRIMARY}${C_BOLD}AICADataKeeper${C_RESET} ${C_MUTED}v${VERSION}${C_RESET}"
  echo ""
  echo -e "${C_TEXT}사용법:${C_RESET} $0 [옵션]"
  echo ""
  echo -e "${C_TEXT}옵션:${C_RESET}"
  echo -e "  ${C_MUTED}--help${C_RESET}    도움말 출력"
  echo ""
  echo -e "${C_TEXT}실행 모드:${C_RESET}"
  echo -e "  ${C_MUTED}sudo${C_RESET}      관리자 메뉴"
  echo -e "  ${C_MUTED}일반${C_RESET}      사용자 메뉴"
  exit 0
fi

if [ "$(id -u)" -eq 0 ]; then
  show_admin_menu_dialog
else
  show_user_menu_dialog
fi
