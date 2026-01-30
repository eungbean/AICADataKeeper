#!/bin/bash

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

ui_wait() {
  $DIALOG_CMD --msgbox "계속하려면 OK를 누르세요" 5 40
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
      --checklist "\n설치할 항목을 선택하세요:\n\n↑↓ 이동 | Space 선택 | Enter 확인" 16 70 5 \
      "GROUP" "공유 그룹 생성" on \
        "입력한 이름으로 새 그룹 생성" \
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
    
     if echo "$CHOICES" | grep -qE "STORAGE|FOLDERS|ENV"; then
       local ALL_USERS=$(getent passwd | cut -d: -f1 | tr '\n' '|' | sed 's/|$//')
       local GROUP_LIST=$(getent group | cut -d: -f1 | grep -vE "^(root|daemon|bin|sys|adm|tty|disk|lp|mail|news|uucp|man|proxy|kmem|dialout|fax|voice|cdrom|floppy|tape|sudo|audio|dip|www-data|backup|operator|list|irc|src|gnats|shadow|utmp|video|sasl|plugdev|staff|games|users|nogroup|systemd|netdev|crontab|messagebus|input|kvm|render|sgx|_ssh|lxd|docker|rdma|ntp|ssl-cert|syslog|uuidd|$ALL_USERS)$" | sort)
      
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
         --checklist "\n권한을 할당할 그룹 선택:\n\n↑↓ 이동 | Space 선택 | Enter 확인" 17 55 6 \
         "${MENU_ITEMS[@]}" \
         3>&1 1>&2 2>&3)
       [ $? -ne 0 ] && return
       
       if [ -z "$GROUPNAME" ]; then
         $DIALOG_CMD --clear --msgbox "최소 하나의 그룹을 선택하세요." 7 35
         return
       fi
       
       # Use first selected group as primary (for chown operations)
       GROUPNAME=$(echo "$GROUPNAME" | tr -d '"' | awk '{print $1}')
    fi
    
    if [ -n "$NEW_GROUPNAME" ]; then
      GROUPNAME=${GROUPNAME:-$NEW_GROUPNAME}
    fi
    
    local LOG_FILE=$(mktemp)
    
    _run_initial_setup "$GROUPNAME" "$CHOICES" "$ENV_CHOICES" "$NEW_GROUPNAME" 2>&1 | \
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
    
    local NEXT_MSG="\n\Zb[다음 단계]\ZB 터미널에서 아래 명령어를 실행하세요:\n"
    NEXT_MSG+="\n  \Zb1.\ZB 그룹 멤버십 적용:\n     \Z4newgrp $GROUPNAME\Zn\n"
    NEXT_MSG+="\n  \Zb2.\ZB 공유 권한 설정 \Z1(필수)\Zn:\n     \Z4echo \"umask 002\" >> ~/.bashrc\n     source ~/.bashrc\Zn\n"
    NEXT_MSG+="\n  \Zb3.\ZB 사용자 추가:\n     \Z4sudo ./main.sh → 사용자 추가\Zn\n"
    NEXT_MSG+="\n\Z3※ 위 명령어는 초기 설정 후 한 번만 실행\Zn"
    
    $DIALOG_CMD --colors --clear --title " 다음 단계 안내 " --msgbox "$NEXT_MSG" 18 55
    rm -f "$LOG_FILE"
}

_run_initial_setup() {
  local GROUPNAME="$1"
  local CHOICES="$2"
  local ENV_CHOICES="$3"
  local NEW_GROUPNAME="$4"
  
  _print_plan() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  설치 계획:"
    echo "$CHOICES" | grep -q "GROUP" && echo "  [ ] 1. 그룹 생성" || echo "  [-] 1. 그룹 생성 (건너뜀)"
    echo "$CHOICES" | grep -q "STORAGE" && echo "  [ ] 2. 저장소 권한" || echo "  [-] 2. 저장소 권한 (건너뜀)"
    echo "$CHOICES" | grep -q "FOLDERS" && echo "  [ ] 3. 폴더 구조" || echo "  [-] 3. 폴더 구조 (건너뜀)"
    echo "$CHOICES" | grep -q "ENV" && echo "  [ ] 4. 개발환경" || echo "  [-] 4. 개발환경 (건너뜀)"
    echo "$CHOICES" | grep -q "SUDOERS" && echo "  [ ] 5. sudoers" || echo "  [-] 5. sudoers (건너뜀)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  }
  
  _print_plan
  
  if echo "$CHOICES" | grep -q "GROUP"; then
    ui_step "1/5" "그룹 생성 중..."
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
  
  if echo "$CHOICES" | grep -q "STORAGE"; then
    ui_step "2/5" "저장소 권한 할당 중..."
    if [ -d /data ]; then
      if chown root:"$GROUPNAME" /data 2>/dev/null && chmod 2775 /data 2>/dev/null; then
        ui_success "/data → root:$GROUPNAME (2775)"
      else
        ui_error "/data 권한 설정 실패 (그룹 '$GROUPNAME' 확인)"
      fi
    else
      ui_warn "/data 디렉토리 없음"
    fi
    if [ -d /backup ]; then
      if chown root:"$GROUPNAME" /backup 2>/dev/null && chmod 2775 /backup 2>/dev/null; then
        ui_success "/backup → root:$GROUPNAME (2775)"
      else
        ui_error "/backup 권한 설정 실패"
      fi
    else
      ui_info "/backup 없음, 건너뜀"
    fi
    echo ""
  fi
  
  if echo "$CHOICES" | grep -q "FOLDERS"; then
    ui_step "3/5" "폴더 구조 생성 중..."
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
    ui_step "4/5" "개발환경 설정 중..."
    
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
    ui_step "5/5" "sudoers 설정 중..."
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
  local USERNAME=""
  
  while [ -z "$USERNAME" ]; do
    USERNAME=$($DIALOG_CMD --clear --inputbox "사용자명을 입력하세요:" 8 40 "" 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
      return 0
    fi
    if [ -z "$USERNAME" ]; then
      $DIALOG_CMD --clear --msgbox "사용자명을 입력하세요." 7 30
    fi
  done
  
   if id "$USERNAME" &>/dev/null; then
     $DIALOG_CMD --clear --yesno "사용자 '$USERNAME' 이미 존재합니다.\n환경 설정만 진행할까요?" 8 45
     if [ $? -ne 0 ]; then
       return 0
     fi
   else
   $DIALOG_CMD --infobox "사용자 생성 중..." 3 25
      adduser --disabled-password --gecos "" "$USERNAME" >/dev/null 2>&1 || {
        $DIALOG_CMD --clear --msgbox "사용자 생성 실패" 6 25
        return 1
      }
      echo "$USERNAME:0000" | chpasswd
      chage -d 0 "$USERNAME"
    fi
  
  # Build group list for checklist (exclude system groups and personal groups)
  local ALL_USERS=$(getent passwd | cut -d: -f1 | tr '\n' '|' | sed 's/|$//')
  local GROUP_LIST=$(getent group | cut -d: -f1 | grep -vE "^(root|daemon|bin|sys|adm|tty|disk|lp|mail|news|uucp|man|proxy|kmem|dialout|fax|voice|cdrom|floppy|tape|sudo|audio|dip|www-data|backup|operator|list|irc|src|gnats|shadow|utmp|video|sasl|plugdev|staff|games|users|nogroup|systemd|netdev|crontab|messagebus|input|kvm|render|sgx|_ssh|lxd|docker|rdma|ntp|ssl-cert|syslog|uuidd|$ALL_USERS)$" | sort)

  local -a GROUP_ITEMS=()
  for g in $GROUP_LIST; do
    GROUP_ITEMS+=("$g" "$g" "off")
  done

  if [ ${#GROUP_ITEMS[@]} -eq 0 ]; then
    $DIALOG_CMD --clear --msgbox "사용 가능한 그룹이 없습니다.\n먼저 초기 설정에서 그룹을 생성하세요." 8 50
    return 1
  fi

  local SELECTED_GROUPS=""
  while [ -z "$SELECTED_GROUPS" ]; do
    SELECTED_GROUPS=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
      --title " 그룹 선택 " \
      --checklist "\n사용자를 추가할 그룹을 선택하세요:\n\n↑↓ 이동 | Space 선택 | Enter 확인" 17 55 6 \
      "${GROUP_ITEMS[@]}" \
      3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
      return 0
    fi

    if [ -z "$SELECTED_GROUPS" ]; then
      $DIALOG_CMD --clear --msgbox "최소 하나의 그룹을 선택하세요." 7 35
    fi
  done

  # Remove quotes and get first group as primary
  SELECTED_GROUPS=$(echo "$SELECTED_GROUPS" | tr -d '"')
  GROUPNAME=$(echo "$SELECTED_GROUPS" | awk '{print $1}')
  
  $DIALOG_CMD --infobox "그룹에 추가 중..." 3 25
  for grp in $SELECTED_GROUPS; do
    usermod -aG "$grp" "$USERNAME"
  done
  
  SSH_CHOICE=$($DIALOG_CMD --clear --menu "SSH 키 설정" 12 50 3 \
    1 "공개키 붙여넣기 (기존 키 사용)" \
    2 "새 키 쌍 생성" \
    3 "건너뛰기 (나중에 설정)" \
    3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]; then
    SSH_CHOICE=3
  fi
  
  local KEY_TYPE="ed25519"
  local SSH_PUBKEY=""
  
  case $SSH_CHOICE in
    1)
      touch /tmp/ssh_key_input.txt
      $DIALOG_CMD --clear --editbox /tmp/ssh_key_input.txt 20 70 2>/tmp/ssh_key_output.txt
      if [ $? -eq 0 ] && [ -s /tmp/ssh_key_output.txt ]; then
        SSH_PUBKEY=$(cat /tmp/ssh_key_output.txt)
      fi
      rm -f /tmp/ssh_key_input.txt /tmp/ssh_key_output.txt
      ;;
    2)
      KEY_TYPE=$($DIALOG_CMD --clear --menu "SSH 키 타입 선택" 12 50 3 \
        "ed25519" "Ed25519 (권장, 빠르고 안전)" \
        "rsa" "RSA 4096-bit (호환성 좋음)" \
        "ecdsa" "ECDSA (타원곡선)" \
        3>&1 1>&2 2>&3)
      if [ $? -ne 0 ]; then
        KEY_TYPE="ed25519"
      fi
      ;;
  esac
  
  local SHELL_CHOICE=$($DIALOG_CMD --clear --menu "쉘 선택" 14 60 4 \
    "bash" "Bash (기본)" \
    "zsh-minimal" "Zsh + oh-my-zsh (minimal)" \
    "zsh-full" "Zsh + oh-my-zsh + plugins (full)" \
    "skip" "건너뛰기" \
    3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]; then
    SHELL_CHOICE="bash"
  fi
  [ "$SHELL_CHOICE" = "skip" ] && SHELL_CHOICE="bash"
  
  local LOG_FILE=$(mktemp)
  local SSH_STATUS="건너뜀"
  [ "$SSH_CHOICE" = "1" ] && SSH_STATUS="공개키 등록"
  [ "$SSH_CHOICE" = "2" ] && SSH_STATUS="새 키 생성 ($KEY_TYPE)"
  local SHELL_STATUS="$SHELL_CHOICE"
  
  {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  사용자 추가: $USERNAME"
    echo "  그룹: $SELECTED_GROUPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  [1/5] 사용자 생성"
    if id "$USERNAME" &>/dev/null; then
      echo "  ✓ 사용자 '$USERNAME' 확인됨"
    fi
    echo ""
    echo "  [2/5] 그룹 추가"
    echo "  ✓ 그룹 '$SELECTED_GROUPS' 추가됨"
    echo ""
    echo "  [3/5] SSH 키 설정"
    echo "  → $SSH_STATUS"
    echo ""
    echo "  [4/5] 쉘 설정"
    echo "  → $SHELL_STATUS"
    echo ""
    echo "  [5/6] 환경 설정"
  } > "$LOG_FILE"
  
  if [ -f "$SCRIPTS_PATH/user-setup.sh" ]; then
    {
      cat "$LOG_FILE"
      "$SCRIPTS_PATH/user-setup.sh" "$USERNAME" "$GROUPNAME" "$SHELL_CHOICE" 2>&1 | \
        sed -u 's/\x1b\[[0-9;]*m//g' | \
        while IFS= read -r line; do
          if [[ "$line" == *"완료"* ]]; then
            echo "  ✓ $line"
          elif [[ "$line" == *"[ERROR]"* ]]; then
            echo "  ✗ $line"
          elif [[ "$line" == *"[INFO]"* ]]; then
            echo "  → ${line#*\[INFO\] }"
          fi
        done
      echo ""
      echo "  [6/6] 완료"
      echo "  ✓ 사용자 '$USERNAME' 설정 완료"
    } | tee "$LOG_FILE" | $DIALOG_CMD --clear --title " 사용자 추가 " --progressbox 20 60
  else
    echo "  ✗ user-setup.sh 없음" >> "$LOG_FILE"
    cat "$LOG_FILE" | $DIALOG_CMD --clear --title " 오류 " --programbox 20 60
    rm -f "$LOG_FILE"
    return 1
  fi
  
  USER_HOME="/data/users/$USERNAME"
  SSH_DIR="$USER_HOME/.ssh"
  
  chown "$USERNAME:$GROUPNAME" "$USER_HOME"
  chmod 750 "$USER_HOME"
  
  case $SSH_CHOICE in
    1)
      if [ -n "$SSH_PUBKEY" ]; then
        mkdir -p "$SSH_DIR"
        echo "$SSH_PUBKEY" > "$SSH_DIR/authorized_keys"
        chown -R "$USERNAME:$GROUPNAME" "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        chmod 600 "$SSH_DIR/authorized_keys"
      fi
      ;;
    2)
      mkdir -p "$SSH_DIR"
      if [ "$KEY_TYPE" = "rsa" ]; then
        ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_$KEY_TYPE" -N "" -C "$USERNAME@aica"
      else
        ssh-keygen -t "$KEY_TYPE" -f "$SSH_DIR/id_$KEY_TYPE" -N "" -C "$USERNAME@aica"
      fi
      cat "$SSH_DIR/id_$KEY_TYPE.pub" >> "$SSH_DIR/authorized_keys"
      chown -R "$USERNAME:$GROUPNAME" "$SSH_DIR"
      chmod 700 "$SSH_DIR"
      chmod 600 "$SSH_DIR/authorized_keys"
      chmod 600 "$SSH_DIR/id_$KEY_TYPE"
      chmod 644 "$SSH_DIR/id_$KEY_TYPE.pub"
      
      clear
      echo ""
      echo -e "${C_ERROR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
      echo -e "${C_ERROR}  ⚠️  SSH 개인키 (Private Key) - 반드시 복사하세요!${C_RESET}"
      echo -e "${C_ERROR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
      echo ""
      echo -e "${C_WARNING}이 키는 다시 표시되지 않습니다!${C_RESET}"
      echo ""
      cat "$SSH_DIR/id_$KEY_TYPE"
      echo ""
      echo -e "${C_MUTED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
      echo ""
      echo -e "${C_TEXT}[사용 방법]${C_RESET}"
      echo ""
      echo -e "${C_MUTED}# 1. 위 개인키를 로컬에 저장${C_RESET}"
      echo -e "${C_TEXT}cat > ~/.ssh/id_${KEY_TYPE}_${USERNAME} << 'EOF'${C_RESET}"
      echo -e "${C_MUTED}(위 개인키 붙여넣기 후 EOF 입력)${C_RESET}"
      echo ""
      echo -e "${C_MUTED}# 2. 권한 설정${C_RESET}"
      echo -e "${C_TEXT}chmod 600 ~/.ssh/id_${KEY_TYPE}_${USERNAME}${C_RESET}"
      echo ""
      echo -e "${C_MUTED}# 3. SSH 접속${C_RESET}"
      echo -e "${C_TEXT}ssh -i ~/.ssh/id_${KEY_TYPE}_${USERNAME} ${USERNAME}@<서버IP>${C_RESET}"
      echo ""
      echo -e "${C_MUTED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
      echo ""
      echo -e "${C_WARNING}복사를 완료했으면 Enter 키를 누르세요...${C_RESET}"
      read -r
      ;;
  esac
  
  echo "" >> "$LOG_FILE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOG_FILE"
  
  local SUMMARY="\n"
  while IFS= read -r line; do
    if [[ "$line" == *"✓"* ]]; then
      line="${line//✓/\\Z2✓\\Zn}"
    elif [[ "$line" == *"✗"* ]]; then
      line="${line//✗/\\Z1✗\\Zn}"
    elif [[ "$line" == *"→"* ]]; then
      line="${line//→/\\Z4→\\Zn}"
    elif [[ "$line" == *"["* && "$line" == *"]"* ]]; then
      line="\\Zb$line\\ZB"
    fi
    SUMMARY+="$line\n"
  done < "$LOG_FILE"
  
  clear
  echo ""
  echo -e "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo -e "${C_SUCCESS}  ✓ 사용자 추가 완료: $USERNAME${C_RESET}"
  echo -e "${C_SUCCESS}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo ""
  cat "$LOG_FILE"
  echo ""
  echo -e "${C_PRIMARY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo -e "${C_PRIMARY}  [사용자 전달 사항] - 아래 내용을 사용자에게 전달하세요${C_RESET}"
  echo -e "${C_PRIMARY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo ""
  echo -e "${C_MUTED}# 1. 초기 비밀번호: 0000${C_RESET}"
  echo -e "${C_WARNING}   ※ 첫 로그인 시 새 비밀번호로 변경 필수${C_RESET}"
  echo -e "${C_WARNING}   ※ 비밀번호 변경 후 자동으로 접속 종료됨 (재접속 필요)${C_RESET}"
  echo ""
  echo -e "${C_MUTED}# 2. SSH 접속${C_RESET}"
  echo -e "${C_TEXT}ssh $USERNAME@<서버IP>${C_RESET}"
  echo -e "${C_MUTED}   Old Password: 0000${C_RESET}"
  echo -e "${C_MUTED}   New Password: (새 비밀번호 입력)${C_RESET}"
  echo ""
  echo -e "${C_MUTED}# 3. 비밀번호 변경 후 재접속${C_RESET}"
  echo -e "${C_TEXT}ssh $USERNAME@<서버IP>${C_RESET}"
  echo ""
  echo -e "${C_MUTED}# 4. 사용자 정보 등록 (선택)${C_RESET}"
  echo -e "${C_TEXT}chfn${C_RESET}"
  echo ""
  echo -e "${C_MUTED}# 5. 환경 설정 적용 (재로그인 또는 아래 실행)${C_RESET}"
  echo -e "${C_TEXT}source ~/.bashrc${C_RESET}"
  echo ""
  echo -e "${C_MUTED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo ""
  echo -e "${C_WARNING}복사를 완료했으면 Enter 키를 누르세요...${C_RESET}"
  read -r
  
  rm -f "$LOG_FILE"
}

admin_delete_user() {
  # Build user list from /data/users/ directory
  local -a USER_ITEMS=()
  local user_count=0
  
  if [ -d /data/users ]; then
    for userdir in /data/users/*/; do
      [ -d "$userdir" ] || continue
      local username=$(basename "$userdir")
      # Skip if not a real user
      id "$username" &>/dev/null || continue
      USER_ITEMS+=("$username" "$username")
      ((user_count++)) || true
    done
  fi
  
  if [ $user_count -eq 0 ]; then
    $DIALOG_CMD --clear --msgbox "삭제할 수 있는 사용자가 없습니다." 7 40
    return 0
  fi
  
  # Select user to delete
  local USERNAME=""
  USERNAME=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
    --title " 사용자 삭제 " \
    --menu "\n삭제할 사용자를 선택하세요:" 15 50 6 \
    "${USER_ITEMS[@]}" \
    3>&1 1>&2 2>&3)
  
  [ $? -ne 0 ] && return 0
  [ -z "$USERNAME" ] && return 0
  
  local USER_HOME="/data/users/$USERNAME"
  local USER_SIZE=$(du -sh "$USER_HOME" 2>/dev/null | cut -f1 || echo "알 수 없음")
  local USER_GROUPS=$(id -nG "$USERNAME" 2>/dev/null | tr ' ' ', ' || echo "알 수 없음")
  local USER_LOGGED_IN=""
  
  if who | grep -q "^${USERNAME} "; then
    USER_LOGGED_IN=$(who | grep "^${USERNAME} " | wc -l)
  fi
  
  if [ -n "$USER_LOGGED_IN" ]; then
    $DIALOG_CMD --colors --clear --backtitle "AICADataKeeper v${VERSION}" \
      --title " ⚠️  로그인 중인 사용자 " \
      --yesno "\n\\Z1\\Zb주의: '$USERNAME' 사용자가 현재 로그인 중입니다!\\ZB\\Zn\n\n세션 수: $USER_LOGGED_IN\n\n로그인 중인 사용자는 삭제할 수 없습니다.\n사용자를 먼저 로그아웃시키거나 세션을 강제 종료해야 합니다.\n\n\\Zb강제로 세션을 종료하고 삭제하시겠습니까?\\ZB" 15 60
    
    if [ $? -ne 0 ]; then
      return 0
    fi
    
    pkill -KILL -u "$USERNAME" 2>/dev/null
    sleep 1
  fi
  
  local WARNING_MSG="\n"
  WARNING_MSG+="\\Z1\\Zb⚠️  경고: 이 작업은 되돌릴 수 없습니다!\\ZB\\Zn\n\n"
  WARNING_MSG+="삭제 대상 사용자: \\Zb$USERNAME\\ZB\n"
  WARNING_MSG+="홈 디렉토리: $USER_HOME\n"
  WARNING_MSG+="데이터 크기: $USER_SIZE\n"
  WARNING_MSG+="소속 그룹: $USER_GROUPS\n\n"
  WARNING_MSG+="\\Z1삭제 시 수행되는 작업:\\Zn\n"
  WARNING_MSG+="  • Linux 사용자 계정 삭제\n"
  WARNING_MSG+="  • 자동 복구 목록에서 제거\n"
  WARNING_MSG+="  • /home/$USERNAME 심볼릭 링크 제거\n"
  
  $DIALOG_CMD --colors --clear --backtitle "AICADataKeeper v${VERSION}" \
    --title " ⚠️  사용자 삭제 경고 " \
    --yesno "$WARNING_MSG" 18 60
  
  [ $? -ne 0 ] && return 0
  
  # Ask about home directory deletion
  local DELETE_HOME="no"
  $DIALOG_CMD --colors --clear --backtitle "AICADataKeeper v${VERSION}" \
    --title " 홈 디렉토리 삭제 " \
    --yesno "\n\\Z1홈 디렉토리도 삭제하시겠습니까?\\Zn\n\n경로: $USER_HOME\n크기: $USER_SIZE\n\n\\Zb이 작업은 되돌릴 수 없습니다!\\ZB" 12 55
  
  if [ $? -eq 0 ]; then
    DELETE_HOME="yes"
  fi
  
  # Final confirmation with username input
  local CONFIRM_INPUT=""
  CONFIRM_INPUT=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
    --title " 최종 확인 " \
    --inputbox "\n정말로 삭제하려면 사용자명을 입력하세요:\n\n삭제 대상: $USERNAME" 12 50 "" \
    3>&1 1>&2 2>&3)
  
  [ $? -ne 0 ] && return 0
  
  if [ "$CONFIRM_INPUT" != "$USERNAME" ]; then
    $DIALOG_CMD --clear --msgbox "사용자명이 일치하지 않습니다.\n삭제가 취소되었습니다." 8 45
    return 0
  fi
  
  # Perform deletion
  local LOG_FILE=$(mktemp)
  {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  사용자 삭제: $USERNAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 1. Remove from users.txt
    echo "  [1/4] 자동 복구 목록에서 제거"
    if [ -f /data/config/users.txt ]; then
      if grep -q "^${USERNAME}:" /data/config/users.txt 2>/dev/null; then
        sed -i "/^${USERNAME}:/d" /data/config/users.txt
        echo "  ✓ users.txt에서 제거됨"
      else
        echo "  → users.txt에 등록되지 않음"
      fi
    else
      echo "  → users.txt 파일 없음"
    fi
    echo ""
    
    # 2. Remove home symlink
    echo "  [2/4] 심볼릭 링크 제거"
    if [ -L "/home/$USERNAME" ]; then
      rm -f "/home/$USERNAME"
      echo "  ✓ /home/$USERNAME 링크 제거됨"
    else
      echo "  → /home/$USERNAME 심볼릭 링크 없음"
    fi
    echo ""
    
    # 3. Delete Linux user
    echo "  [3/4] Linux 사용자 삭제"
    if id "$USERNAME" &>/dev/null; then
      if userdel "$USERNAME" 2>/dev/null; then
        echo "  ✓ 사용자 '$USERNAME' 삭제됨"
      else
        echo "  ✗ 사용자 삭제 실패"
      fi
    else
      echo "  → 사용자 '$USERNAME' 존재하지 않음"
    fi
    echo ""
    
    # 4. Delete home directory (optional)
    echo "  [4/4] 홈 디렉토리"
    if [ "$DELETE_HOME" = "yes" ]; then
      if [ -d "$USER_HOME" ]; then
        rm -rf "$USER_HOME"
        echo "  ✓ $USER_HOME 삭제됨"
      else
        echo "  → 홈 디렉토리 없음"
      fi
    else
      echo "  → 보존됨 ($USER_HOME)"
    fi
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✓ 사용자 삭제 완료"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  } > "$LOG_FILE" 2>&1
  
  # Show result with colors
  local SUMMARY="\n"
  while IFS= read -r line; do
    if [[ "$line" == *"✓"* ]]; then
      line="${line//✓/\\Z2✓\\Zn}"
    elif [[ "$line" == *"✗"* ]]; then
      line="${line//✗/\\Z1✗\\Zn}"
    elif [[ "$line" == *"→"* ]]; then
      line="${line//→/\\Z4→\\Zn}"
    elif [[ "$line" == *"["* && "$line" == *"]"* ]]; then
      line="\\Zb$line\\ZB"
    fi
    SUMMARY+="$line\n"
  done < "$LOG_FILE"
  
  $DIALOG_CMD --colors --clear --title " 삭제 완료 " --msgbox "$SUMMARY" 22 55
  
  rm -f "$LOG_FILE"
}

admin_install_packages() {
  local SELECTED_PACKAGES=$($DIALOG_CMD --clear --backtitle "AICADataKeeper v${VERSION}" \
    --title " 글로벌 패키지 설치 " \
    --checklist "\n설치할 패키지를 선택하세요:\n\n↑↓ 이동 | Space 선택 | Enter 확인" 18 70 6 \
    "oh-my-opencode" "AI 코딩 어시스턴트 (oh-my-opencode)" off \
    "cli_tools" "CLI 도구 (fzf, ripgrep, fd, bat)" off \
    "neovim" "현대적 vim 에디터" off \
    "btop" "시스템 모니터" off \
    "nvtop" "GPU 모니터" off \
    "ruff" "빠른 Python 린터" off \
    3>&1 1>&2 2>&3)
  
  if [ $? -ne 0 ] || [ -z "$SELECTED_PACKAGES" ]; then
    return 0
  fi
  
  SELECTED_PACKAGES=$(echo "$SELECTED_PACKAGES" | tr -d '"')
  
  local LOG_FILE=$(mktemp)
  local RESULTS=""
  local TOTAL=$(echo "$SELECTED_PACKAGES" | wc -w)
  local CURRENT=0
  
  # 패키지 목록 업데이트
  $DIALOG_CMD --infobox "패키지 목록 업데이트 중..." 3 35
  apt-get update -qq >/dev/null 2>&1 || true
  
  for pkg in $SELECTED_PACKAGES; do
    CURRENT=$((CURRENT + 1))
    
    case $pkg in
      oh-my-opencode)
        # Step 1: bun
        $DIALOG_CMD --infobox "[$CURRENT/$TOTAL] oh-my-opencode 설치 중...\n\n[1/3] bun 설치 확인..." 6 45
        local BUN_OK=false
        if bun --version &>/dev/null; then
          BUN_OK=true
          RESULTS="${RESULTS}✓ bun (이미 설치됨)\n"
        else
          rm -f /usr/local/bin/bun /usr/local/bin/bunx 2>/dev/null || true
          bash -c 'curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash' </dev/null >>"$LOG_FILE" 2>&1 || true
          export PATH="/usr/local/bin:$PATH"
          if [ -x /usr/local/bin/bun ]; then
            ln -sf /usr/local/bin/bun /usr/local/bin/bunx 2>/dev/null || true
            BUN_OK=true
            RESULTS="${RESULTS}✓ bun 설치 완료\n"
          else
            RESULTS="${RESULTS}⚠ bun 설치 실패\n"
          fi
        fi
        
        # Step 2: opencode CLI
        $DIALOG_CMD --infobox "[$CURRENT/$TOTAL] oh-my-opencode 설치 중...\n\n[2/3] opencode CLI 설치..." 6 45
        local OPENCODE_BIN=""
        if opencode --version &>/dev/null; then
          OPENCODE_BIN=$(which opencode)
          RESULTS="${RESULTS}✓ opencode CLI (이미 설치됨)\n"
        elif [ -f /root/.opencode/bin/opencode ]; then
          OPENCODE_BIN="/root/.opencode/bin/opencode"
          ln -sf "$OPENCODE_BIN" /usr/local/bin/opencode 2>/dev/null || true
          RESULTS="${RESULTS}✓ opencode CLI (링크 생성)\n"
        elif [ -f /home/ubuntu/.opencode/bin/opencode ]; then
          OPENCODE_BIN="/home/ubuntu/.opencode/bin/opencode"
          ln -sf "$OPENCODE_BIN" /usr/local/bin/opencode 2>/dev/null || true
          RESULTS="${RESULTS}✓ opencode CLI (기존 설치 링크)\n"
        else
          bash -c 'curl -fsSL https://opencode.ai/install.sh | bash' </dev/null >>"$LOG_FILE" 2>&1 || true
          if [ -f /root/.opencode/bin/opencode ]; then
            OPENCODE_BIN="/root/.opencode/bin/opencode"
            ln -sf "$OPENCODE_BIN" /usr/local/bin/opencode 2>/dev/null || true
            RESULTS="${RESULTS}✓ opencode CLI 설치 완료\n"
          else
            RESULTS="${RESULTS}⚠ opencode CLI 설치 실패\n"
          fi
        fi
        
        # Step 3: oh-my-opencode plugin
        $DIALOG_CMD --infobox "[$CURRENT/$TOTAL] oh-my-opencode 설치 중...\n\n[3/3] oh-my-opencode 플러그인..." 6 45
        if [ "$BUN_OK" = true ]; then
          /usr/local/bin/bun x oh-my-opencode install --no-tui --claude=no --gemini=no --copilot=no --openai=no >>"$LOG_FILE" 2>&1 || true
          RESULTS="${RESULTS}✓ oh-my-opencode 플러그인 설치 완료\n"
        else
          RESULTS="${RESULTS}⚠ bun 없음 - 플러그인 설치 생략\n"
        fi
        RESULTS="${RESULTS}  → 인증: opencode auth login\n\n"
        ;;
        
      cli_tools)
        $DIALOG_CMD --infobox "[$CURRENT/$TOTAL] CLI 도구 설치 중...\n\n(fzf, ripgrep, fd, bat)" 6 40
        apt-get install -y fzf ripgrep fd-find bat >>"$LOG_FILE" 2>&1 || true
        ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
        ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
        RESULTS="${RESULTS}✓ CLI 도구 (fzf, rg, fd, bat)\n"
        ;;
        
      neovim)
        $DIALOG_CMD --infobox "[$CURRENT/$TOTAL] neovim 설치 중..." 4 35
        apt-get install -y neovim >>"$LOG_FILE" 2>&1 && RESULTS="${RESULTS}✓ neovim\n" || RESULTS="${RESULTS}⚠ neovim 실패\n"
        ;;
        
      btop)
        $DIALOG_CMD --infobox "[$CURRENT/$TOTAL] btop 설치 중..." 4 35
        apt-get install -y btop >>"$LOG_FILE" 2>&1 && RESULTS="${RESULTS}✓ btop\n" || RESULTS="${RESULTS}⚠ btop 실패\n"
        ;;
        
      nvtop)
        $DIALOG_CMD --infobox "[$CURRENT/$TOTAL] nvtop 설치 중..." 4 35
        apt-get install -y nvtop >>"$LOG_FILE" 2>&1 && RESULTS="${RESULTS}✓ nvtop\n" || RESULTS="${RESULTS}⚠ nvtop 실패\n"
        ;;
        
      ruff)
        $DIALOG_CMD --infobox "[$CURRENT/$TOTAL] ruff 설치 중..." 4 35
        if command -v uv &> /dev/null; then
          uv tool install ruff >>"$LOG_FILE" 2>&1 && RESULTS="${RESULTS}✓ ruff (uv)\n" || RESULTS="${RESULTS}⚠ ruff 실패\n"
        else
          pip3 install --break-system-packages ruff >>"$LOG_FILE" 2>&1 && RESULTS="${RESULTS}✓ ruff (pip)\n" || RESULTS="${RESULTS}⚠ ruff 실패\n"
        fi
        ;;
    esac
  done
  
  rm -f "$LOG_FILE"
  
  $DIALOG_CMD --clear --title " 설치 완료 " --msgbox "글로벌 패키지 설치 결과:\n\n${RESULTS}" 18 50
}

admin_auto_recovery() {
  RECOVERY_CHOICE=$($DIALOG_CMD --clear --menu "자동 복구 관리" 14 50 4 \
    1 "활성화 - 서비스 시작" \
    2 "비활성화 - 서비스 중지" \
    3 "상태 확인" \
    4 "수동 실행 - 지금 복구 실행" \
    3>&1 1>&2 2>&3)
  
  [ $? -ne 0 ] && return 0
  
  case "$RECOVERY_CHOICE" in
    1)
      $DIALOG_CMD --infobox "복구 서비스 활성화 중..." 3 35
      if systemctl enable aica-recovery.service 2>/dev/null; then
        systemctl start aica-recovery.service 2>/dev/null || true
        $DIALOG_CMD --msgbox "복구 서비스 활성화됨" 5 35
      else
        $DIALOG_CMD --msgbox "aica-recovery.service 없음\n서비스 파일을 먼저 생성하세요" 7 45
      fi
      ;;
    2)
      $DIALOG_CMD --infobox "복구 서비스 비활성화 중..." 3 35
      if systemctl disable aica-recovery.service 2>/dev/null; then
        systemctl stop aica-recovery.service 2>/dev/null || true
        $DIALOG_CMD --msgbox "복구 서비스 비활성화됨" 5 35
      else
        $DIALOG_CMD --msgbox "서비스 미설치" 5 25
      fi
      ;;
    3)
      STATUS=$(systemctl status aica-recovery.service 2>&1) || STATUS="서비스 미설치"
      $DIALOG_CMD --msgbox "$STATUS" 20 70
      ;;
    4)
      $DIALOG_CMD --infobox "수동 복구 실행 중..." 3 30
      if [ -f "$SCRIPTS_PATH/ops-recovery.sh" ]; then
        "$SCRIPTS_PATH/ops-recovery.sh"
        $DIALOG_CMD --msgbox "복구 완료" 5 20
      else
        $DIALOG_CMD --msgbox "ops-recovery.sh 없음" 5 30
      fi
      ;;
  esac
}

_detect_test_params() {
  TEST_GROUP=""
  
  if [ -f /data/config/users.txt ]; then
    while IFS=: read -r username groupname; do
      [[ "$username" =~ ^#.*$ ]] && continue
      [ -z "$username" ] && continue
      TEST_GROUP="$groupname"
      break
    done < /data/config/users.txt
  fi
  
  if [ -z "$TEST_GROUP" ] && [ -d /data ]; then
    TEST_GROUP=$(stat -c %G /data 2>/dev/null || echo "")
  fi
  
  [ -z "$TEST_GROUP" ] && TEST_GROUP="gpu-users" || true
}

_run_setup_tests() {
  local GROUP="$1"
  
  PASS_COUNT=0
  FAIL_COUNT=0
  SKIP_COUNT=0
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  초기 설정 테스트"
  echo "  그룹: $GROUP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  ui_step "1/5" "그룹 생성"
  if getent group "$GROUP" > /dev/null 2>&1; then
    ui_success "그룹 '$GROUP' 존재"
    ((++PASS_COUNT)) || true
  else
    ui_error "그룹 '$GROUP' 없음"
    ((++FAIL_COUNT)) || true
  fi
  echo ""
  
  ui_step "2/5" "저장소 권한"
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
  
  ui_step "3/5" "폴더 구조"
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
  
  ui_step "4/5" "개발환경"
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
  
  ui_step "5/5" "sudoers"
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
  
  _run_setup_tests "$TEST_GROUP" 2>&1 | \
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
      --menu "\n작업을 선택하세요:" 16 55 7 \
      1 "초기 설정" \
      2 "설정 테스트" \
      3 "사용자 추가" \
      4 "사용자 삭제" \
      5 "글로벌 패키지 설치" \
      6 "자동 복구" \
      q "종료" \
      3>&1 1>&2 2>&3)
    
    [ $? -ne 0 ] && { clear; exit 0; }
    
    case $CHOICE in
      1) admin_initial_setup ;;
      2) admin_test_config ;;
      3) admin_add_user ;;
      4) admin_delete_user ;;
      5) admin_install_packages ;;
      6) admin_auto_recovery ;;
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
  choice=$($DIALOG_CMD --clear --menu "캐시 정리\n(공유 캐시 - 다른 사용자에게 영향 줄 수 있음)" 16 55 5 \
    1 "Conda - conda 패키지 캐시" \
    2 "Pip - pip 패키지 캐시" \
    3 "PyTorch - 모델 캐시" \
    4 "HuggingFace - 모델 캐시" \
    5 "전체 - 모든 캐시" \
    3>&1 1>&2 2>&3)
  
  [ $? -ne 0 ] && return 0
  
  case $choice in
    1)
      $DIALOG_CMD --infobox "Conda 캐시 정리 중..." 3 30
      if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --conda 2>/dev/null; then
        $DIALOG_CMD --msgbox "Conda 캐시 정리됨" 5 30
      else
        $DIALOG_CMD --msgbox "캐시 정리 권한 없음" 5 30
      fi
      ;;
    2)
      $DIALOG_CMD --infobox "Pip 캐시 정리 중..." 3 30
      if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --pip 2>/dev/null; then
        $DIALOG_CMD --msgbox "Pip 캐시 정리됨" 5 30
      else
        $DIALOG_CMD --msgbox "캐시 정리 권한 없음" 5 30
      fi
      ;;
    3)
      $DIALOG_CMD --infobox "PyTorch 캐시 정리 중..." 3 35
      if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --torch 2>/dev/null; then
        $DIALOG_CMD --msgbox "PyTorch 캐시 정리됨" 5 30
      else
        $DIALOG_CMD --msgbox "캐시 정리 권한 없음" 5 30
      fi
      ;;
    4)
      $DIALOG_CMD --infobox "HuggingFace 캐시 정리 중..." 3 35
      if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --hf 2>/dev/null; then
        $DIALOG_CMD --msgbox "HuggingFace 캐시 정리됨" 5 35
      else
        $DIALOG_CMD --msgbox "캐시 정리 권한 없음" 5 30
      fi
      ;;
    5)
      $DIALOG_CMD --yesno "정말 모든 캐시를 정리하시겠습니까?\n이 작업은 되돌릴 수 없습니다." 8 45
      if [ $? -eq 0 ]; then
        $DIALOG_CMD --infobox "모든 캐시 정리 중..." 3 30
        if sudo -n "$SCRIPTS_PATH/ops-clean-cache.sh" --all 2>/dev/null; then
          $DIALOG_CMD --msgbox "모든 캐시 정리됨" 5 30
        else
          $DIALOG_CMD --msgbox "캐시 정리 권한 없음" 5 30
        fi
      fi
      ;;
  esac
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
