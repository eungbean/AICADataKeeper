#!/bin/bash
# [07] 대화형 관리자 위자드
# 역할: 시스템 설정 작업 통합 메뉴 UI

set -e

# 도움말 표시
function show_help {
  cat << EOF
AICADataKeeper 설정 위자드

사용법: sudo $0 [옵션]

옵션:
  --help          이 도움말 표시
  --list-options  메뉴 항목 목록 출력 (테스트용)

메뉴 항목:
  1. 글로벌 환경 설치
  2. 새 사용자 추가
  3. 권한 설정
  4. 자동 복구 설정
  5. 설정 테스트
  6. 캐시 설정
  7. uv 설치
  8. 종료

설명:
  이 스크립트는 AICADataKeeper 시스템 관리 작업을 위한
  대화형 메뉴 인터페이스를 제공합니다.
EOF
}

# 메뉴 항목 목록 출력
function list_options {
  cat << EOF
1. 글로벌 환경 설치 (Install Global Environment)
2. 새 사용자 추가 (Add New User)
3. 권한 설정 (Setup Permissions)
4. 자동 복구 설정 (Configure Auto-Recovery)
5. 설정 테스트 (Test Configuration)
6. 캐시 설정 (Setup Cache Config)
7. uv 설치 (Setup uv)
8. 종료 (Exit)
EOF
}

# 옵션 처리
if [ $# -gt 0 ]; then
  case "$1" in
    --help)
      show_help
      exit 0
      ;;
    --list-options)
      list_options
      exit 0
      ;;
    *)
      echo "[ERROR] 알 수 없는 옵션: $1"
      show_help
      exit 1
      ;;
  esac
fi

# Root 권한 확인
if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0"
  exit 1
fi

# 스크립트 위치 기준 절대 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dialog/Whiptail 감지
if command -v dialog &> /dev/null; then
  DIALOG_CMD="dialog"
elif command -v whiptail &> /dev/null; then
  DIALOG_CMD="whiptail"
else
  DIALOG_CMD="text"
fi

# 임시 파일 경로
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# 메뉴 항목 1: 글로벌 환경 설치
function menu_install_global {
  echo ""
  echo "=========================================="
  echo " 글로벌 환경 설치"
  echo "=========================================="
  echo ""
  
  read -p "그룹명을 입력하세요 (기본값: gpu-users): " GROUPNAME
  GROUPNAME=${GROUPNAME:-gpu-users}
  
  echo "[INFO] 글로벌 환경 설치를 시작합니다..."
  if [ -f "$SCRIPT_DIR/setup_global_after_startup.sh" ]; then
    "$SCRIPT_DIR/setup_global_after_startup.sh" "$GROUPNAME"
    echo "[INFO] 글로벌 환경 설치 완료"
  else
    echo "[ERROR] setup_global_after_startup.sh 파일을 찾을 수 없습니다."
    return 1
  fi
  
  read -p "계속하려면 Enter를 누르세요..."
}

# 메뉴 항목 2: 새 사용자 추가
function menu_add_user {
  echo ""
  echo "=========================================="
  echo " 새 사용자 추가"
  echo "=========================================="
  echo ""
  
  read -p "사용자명을 입력하세요: " USERNAME
  if [ -z "$USERNAME" ]; then
    echo "[ERROR] 사용자명이 입력되지 않았습니다."
    read -p "계속하려면 Enter를 누르세요..."
    return 1
  fi
  
  read -p "그룹명을 입력하세요 (기본값: gpu-users): " GROUPNAME
  GROUPNAME=${GROUPNAME:-gpu-users}
  
  echo "[INFO] 사용자 $USERNAME 추가를 시작합니다..."
  if [ -f "$SCRIPT_DIR/setup_new_user.sh" ]; then
    "$SCRIPT_DIR/setup_new_user.sh" "$USERNAME" "$GROUPNAME"
    echo "[INFO] 사용자 추가 완료"
  else
    echo "[ERROR] setup_new_user.sh 파일을 찾을 수 없습니다."
    return 1
  fi
  
  read -p "계속하려면 Enter를 누르세요..."
}

# 메뉴 항목 3: 권한 설정
function menu_setup_permissions {
  echo ""
  echo "=========================================="
  echo " 권한 설정"
  echo "=========================================="
  echo ""
  
  echo "[INFO] 권한 설정을 시작합니다..."
  
  if [ -f "$SCRIPT_DIR/setup_permissions.sh" ]; then
    "$SCRIPT_DIR/setup_permissions.sh"
    echo "[INFO] setup_permissions.sh 실행 완료"
  else
    echo "[WARNING] setup_permissions.sh 파일을 찾을 수 없습니다."
  fi
  
  if [ -f "$SCRIPT_DIR/setup_sudoers.sh" ]; then
    "$SCRIPT_DIR/setup_sudoers.sh"
    echo "[INFO] setup_sudoers.sh 실행 완료"
  else
    echo "[WARNING] setup_sudoers.sh 파일을 찾을 수 없습니다."
  fi
  
  echo "[INFO] 권한 설정 완료"
  read -p "계속하려면 Enter를 누르세요..."
}

# 메뉴 항목 4: 자동 복구 설정
function menu_auto_recovery {
  echo ""
  echo "=========================================="
  echo " 자동 복구 설정"
  echo "=========================================="
  echo ""
  echo "1. 자동 복구 활성화"
  echo "2. 자동 복구 비활성화"
  echo "3. 자동 복구 상태 확인"
  echo ""
  read -p "선택하세요 (1-3): " RECOVERY_CHOICE
  
  case "$RECOVERY_CHOICE" in
    1)
      echo "[INFO] 자동 복구 서비스를 활성화합니다..."
      if systemctl enable aica-recovery.service 2>/dev/null; then
        systemctl start aica-recovery.service 2>/dev/null || true
        echo "[INFO] 자동 복구 서비스 활성화 완료"
      else
        echo "[ERROR] aica-recovery.service를 찾을 수 없습니다."
        echo "[INFO] 서비스 파일을 먼저 생성해야 합니다."
      fi
      ;;
    2)
      echo "[INFO] 자동 복구 서비스를 비활성화합니다..."
      if systemctl disable aica-recovery.service 2>/dev/null; then
        systemctl stop aica-recovery.service 2>/dev/null || true
        echo "[INFO] 자동 복구 서비스 비활성화 완료"
      else
        echo "[WARNING] aica-recovery.service가 설치되어 있지 않습니다."
      fi
      ;;
    3)
      echo "[INFO] 자동 복구 서비스 상태:"
      systemctl status aica-recovery.service 2>/dev/null || echo "[INFO] 서비스가 설치되어 있지 않습니다."
      ;;
    *)
      echo "[ERROR] 잘못된 선택입니다."
      ;;
  esac
  
  read -p "계속하려면 Enter를 누르세요..."
}

# 메뉴 항목 5: 설정 테스트
function menu_test_config {
  echo ""
  echo "=========================================="
  echo " 설정 테스트"
  echo "=========================================="
  echo ""
  
  PASS_COUNT=0
  FAIL_COUNT=0
  
  # 테스트 1: 스크립트 문법 검사
  echo "[TEST 1] 스크립트 문법 검사..."
  if bash -n "$SCRIPT_DIR"/*.sh 2>/dev/null; then
    echo "  ✓ PASS: 모든 스크립트 문법 정상"
    ((PASS_COUNT++))
  else
    echo "  ✗ FAIL: 스크립트 문법 오류 발견"
    ((FAIL_COUNT++))
  fi
  
  # 테스트 2: 환경 파일 확인
  echo "[TEST 2] 환경 파일 확인..."
  if [ -f /etc/profile.d/global_envs.sh ]; then
    echo "  ✓ PASS: /etc/profile.d/global_envs.sh 존재"
    ((PASS_COUNT++))
  else
    echo "  ✗ FAIL: /etc/profile.d/global_envs.sh 없음"
    ((FAIL_COUNT++))
  fi
  
  # 테스트 3: Miniconda 설치 확인
  echo "[TEST 3] Miniconda 설치 확인..."
  if [ -d /data/apps/miniconda3 ]; then
    echo "  ✓ PASS: /data/apps/miniconda3 존재"
    ((PASS_COUNT++))
  else
    echo "  ✗ FAIL: /data/apps/miniconda3 없음"
    ((FAIL_COUNT++))
  fi
  
  # 테스트 4: 사용자 레지스트리 확인
  echo "[TEST 4] 사용자 레지스트리 확인..."
  if [ -f /data/config/users.txt ]; then
    echo "  ✓ PASS: /data/config/users.txt 존재"
    ((PASS_COUNT++))
  else
    echo "  ✗ FAIL: /data/config/users.txt 없음"
    ((FAIL_COUNT++))
  fi
  
  # 테스트 5: 캐시 디렉토리 확인
  echo "[TEST 5] 캐시 디렉토리 확인..."
  if [ -d /data/cache ]; then
    echo "  ✓ PASS: /data/cache 존재"
    ((PASS_COUNT++))
  else
    echo "  ✗ FAIL: /data/cache 없음"
    ((FAIL_COUNT++))
  fi
  
  echo ""
  echo "=========================================="
  echo " 테스트 결과: $PASS_COUNT 통과, $FAIL_COUNT 실패"
  echo "=========================================="
  
  read -p "계속하려면 Enter를 누르세요..."
}

# 메뉴 항목 6: 캐시 설정
function menu_cache_config {
  echo ""
  echo "=========================================="
  echo " 캐시 설정"
  echo "=========================================="
  echo ""
  
  echo "[INFO] 캐시 설정을 시작합니다..."
  if [ -f "$SCRIPT_DIR/setup_cache_config.sh" ]; then
    "$SCRIPT_DIR/setup_cache_config.sh"
    echo "[INFO] 캐시 설정 완료"
  else
    echo "[WARNING] setup_cache_config.sh 파일을 찾을 수 없습니다."
    echo "[INFO] 이 기능은 아직 구현되지 않았을 수 있습니다."
  fi
  
  read -p "계속하려면 Enter를 누르세요..."
}

# 메뉴 항목 7: uv 설치
function menu_setup_uv {
  echo ""
  echo "=========================================="
  echo " uv 설치"
  echo "=========================================="
  echo ""
  
  echo "[INFO] uv 설치를 시작합니다..."
  if [ -f "$SCRIPT_DIR/setup_uv.sh" ]; then
    "$SCRIPT_DIR/setup_uv.sh"
    echo "[INFO] uv 설치 완료"
  else
    echo "[ERROR] setup_uv.sh 파일을 찾을 수 없습니다."
    return 1
  fi
  
  read -p "계속하려면 Enter를 누르세요..."
}

# Dialog/Whiptail 메뉴 표시
function show_dialog_menu {
  $DIALOG_CMD --title "AICADataKeeper 설정 위자드" \
    --menu "작업을 선택하세요:" 20 60 8 \
    1 "글로벌 환경 설치" \
    2 "새 사용자 추가" \
    3 "권한 설정" \
    4 "자동 복구 설정" \
    5 "설정 테스트" \
    6 "캐시 설정" \
    7 "uv 설치" \
    8 "종료" \
    2>$TEMP_FILE
  
  return $?
}

# 텍스트 메뉴 표시
function show_text_menu {
  clear
  cat << EOF

========================================
  AICADataKeeper 설정 위자드
========================================

1. 글로벌 환경 설치
2. 새 사용자 추가
3. 권한 설정
4. 자동 복구 설정
5. 설정 테스트
6. 캐시 설정
7. uv 설치
8. 종료

========================================
EOF
  read -p "선택하세요 (1-8): " CHOICE
  echo "$CHOICE" > $TEMP_FILE
  return 0
}

# 메인 루프
function main_loop {
  while true; do
    # 메뉴 표시
    if [ "$DIALOG_CMD" != "text" ]; then
      if ! show_dialog_menu; then
        # ESC 또는 Cancel 선택 시 종료
        clear
        echo "[INFO] 설정 위자드를 종료합니다."
        exit 0
      fi
    else
      show_text_menu
    fi
    
    # 선택 읽기
    CHOICE=$(cat $TEMP_FILE)
    
    # 선택 처리
    case "$CHOICE" in
      1)
        menu_install_global
        ;;
      2)
        menu_add_user
        ;;
      3)
        menu_setup_permissions
        ;;
      4)
        menu_auto_recovery
        ;;
      5)
        menu_test_config
        ;;
      6)
        menu_cache_config
        ;;
      7)
        menu_setup_uv
        ;;
      8)
        clear
        echo "[INFO] 설정 위자드를 종료합니다."
        exit 0
        ;;
      *)
        if [ "$DIALOG_CMD" != "text" ]; then
          $DIALOG_CMD --msgbox "잘못된 선택입니다." 8 40
        else
          echo "[ERROR] 잘못된 선택입니다."
          read -p "계속하려면 Enter를 누르세요..."
        fi
        ;;
    esac
  done
}

# 메인 실행
echo "[INFO] AICADataKeeper 설정 위자드를 시작합니다..."
echo "[INFO] 사용 중인 UI: $DIALOG_CMD"
sleep 1

main_loop
