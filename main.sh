#!/bin/bash
# AICADataKeeper - 사용자 인터랙티브 터미널
# 일반 사용자를 위한 환경 관리 메뉴

set -e

DIALOG_CMD=""
if command -v dialog &> /dev/null; then
  DIALOG_CMD="dialog"
elif command -v whiptail &> /dev/null; then
  DIALOG_CMD="whiptail"
else
  DIALOG_CMD="text"
fi

show_header() {
  clear
  echo "======================================"
  echo "  AICADataKeeper - 사용자 메뉴"
  echo "======================================"
  echo ""
}

show_environment_info() {
  show_header
  echo "[환경 정보]"
  echo ""
  echo "사용자: $(whoami)"
  echo "그룹: $(groups)"
  echo "홈 디렉토리: $HOME"
  
  if [ -L "$HOME" ]; then
    echo "  → 실제 위치: $(readlink -f "$HOME")"
  fi
  
  echo ""
  echo "[환경 변수]"
  if [ -f /etc/profile.d/global_envs.sh ]; then
    source /etc/profile.d/global_envs.sh
    echo "PIP_CACHE_DIR: $PIP_CACHE_DIR"
    echo "CONDA_PKGS_DIRS: $CONDA_PKGS_DIRS"
    echo "UV_CACHE_DIR: $UV_CACHE_DIR"
    echo "TORCH_HOME: $TORCH_HOME"
    echo "HF_HOME: $HF_HOME"
  else
    echo "전역 환경 변수가 설정되지 않았습니다."
  fi
  
  echo ""
  echo "[Conda 환경]"
  if command -v conda &> /dev/null; then
    echo "Conda 버전: $(conda --version)"
    echo "활성 환경: ${CONDA_DEFAULT_ENV:-base}"
    echo ""
    echo "내 Conda 환경 목록:"
    conda env list 2>/dev/null | grep -E "^[^#]" || echo "  환경이 없습니다."
  else
    echo "Conda가 설치되지 않았습니다."
  fi
  
  echo ""
  read -p "Enter를 눌러 계속..."
}

show_disk_usage() {
  show_header
  echo "[디스크 사용량]"
  echo ""
  
  if sudo -n df -h /data 2>/dev/null; then
    echo ""
    echo "[캐시 사용량]"
    if [ -d /data/cache ]; then
      du -sh /data/cache/* 2>/dev/null || echo "캐시 정보를 가져올 수 없습니다."
    fi
    
    echo ""
    echo "[내 홈 디렉토리 사용량]"
    du -sh "$HOME" 2>/dev/null || echo "홈 디렉토리 정보를 가져올 수 없습니다."
  else
    echo "디스크 정보 확인 권한이 없습니다."
    echo "관리자에게 sudoers 설정을 요청하세요."
  fi
  
  echo ""
  read -p "Enter를 눌러 계속..."
}

clean_cache_menu() {
  show_header
  echo "[캐시 정리]"
  echo ""
  echo "공유 캐시를 정리할 수 있습니다."
  echo "주의: 다른 사용자의 작업에 영향을 줄 수 있습니다."
  echo ""
  echo "1. Conda 캐시 정리"
  echo "2. Pip 캐시 정리"
  echo "3. PyTorch 모델 캐시 정리"
  echo "4. HuggingFace 캐시 정리"
  echo "5. 모든 캐시 정리"
  echo "6. 돌아가기"
  echo ""
  
  read -p "선택 [1-6]: " choice
  
  case $choice in
    1)
      if sudo -n /data/scripts/clean_cache.sh --conda 2>/dev/null; then
        echo "[성공] Conda 캐시가 정리되었습니다."
      else
        echo "[실패] 캐시 정리 권한이 없습니다."
      fi
      ;;
    2)
      if sudo -n /data/scripts/clean_cache.sh --pip 2>/dev/null; then
        echo "[성공] Pip 캐시가 정리되었습니다."
      else
        echo "[실패] 캐시 정리 권한이 없습니다."
      fi
      ;;
    3)
      if sudo -n /data/scripts/clean_cache.sh --torch 2>/dev/null; then
        echo "[성공] PyTorch 캐시가 정리되었습니다."
      else
        echo "[실패] 캐시 정리 권한이 없습니다."
      fi
      ;;
    4)
      if sudo -n /data/scripts/clean_cache.sh --hf 2>/dev/null; then
        echo "[성공] HuggingFace 캐시가 정리되었습니다."
      else
        echo "[실패] 캐시 정리 권한이 없습니다."
      fi
      ;;
    5)
      echo "정말 모든 캐시를 정리하시겠습니까? [y/N]"
      read -p "> " confirm
      if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        if sudo -n /data/scripts/clean_cache.sh --all 2>/dev/null; then
          echo "[성공] 모든 캐시가 정리되었습니다."
        else
          echo "[실패] 캐시 정리 권한이 없습니다."
        fi
      else
        echo "취소되었습니다."
      fi
      ;;
    6)
      return
      ;;
    *)
      echo "잘못된 선택입니다."
      ;;
  esac
  
  echo ""
  read -p "Enter를 눌러 계속..."
}

show_conda_guide() {
  show_header
  echo "[Conda 환경 관리 가이드]"
  echo ""
  echo "=== 새 환경 생성 ==="
  echo "conda create -n myenv python=3.10"
  echo ""
  echo "=== 환경 활성화 ==="
  echo "conda activate myenv"
  echo ""
  echo "=== 패키지 설치 ==="
  echo "conda install numpy pandas"
  echo "# 또는"
  echo "pip install torch torchvision"
  echo "# 또는 (더 빠름)"
  echo "uv pip install transformers"
  echo ""
  echo "=== 환경 목록 확인 ==="
  echo "conda env list"
  echo ""
  echo "=== 환경 삭제 ==="
  echo "conda env remove -n myenv"
  echo ""
  echo "=== 주의사항 ==="
  echo "- 패키지 캐시는 모든 사용자와 공유됩니다"
  echo "- 환경은 $HOME/conda/envs에 저장됩니다"
  echo "- 큰 모델 다운로드 시 다른 사용자에게 미리 알려주세요"
  echo ""
  read -p "Enter를 눌러 계속..."
}

show_package_guide() {
  show_header
  echo "[패키지 설치 가이드]"
  echo ""
  echo "=== Conda로 설치 (추천) ==="
  echo "conda install package-name"
  echo "  장점: 환경 관리 용이, 바이너리 패키지 제공"
  echo ""
  echo "=== Pip로 설치 ==="
  echo "pip install package-name"
  echo "  장점: 최신 패키지, PyPI 전체 접근"
  echo ""
  echo "=== uv로 설치 (가장 빠름) ==="
  echo "uv pip install package-name"
  echo "  장점: pip보다 10-100배 빠름"
  echo ""
  echo "=== 캐시 경로 ==="
  echo "- Conda: /data/cache/conda/pkgs"
  echo "- Pip: /data/cache/pip"
  echo "- uv: /data/cache/uv"
  echo ""
  echo "=== 주의사항 ==="
  echo "- 신뢰할 수 있는 소스에서만 설치하세요"
  echo "- 큰 패키지 설치 전 디스크 공간 확인"
  echo "- requirements.txt 사용 권장: pip install -r requirements.txt"
  echo ""
  read -p "Enter를 눌러 계속..."
}

show_help() {
  show_header
  echo "[도움말]"
  echo ""
  echo "=== 문제 해결 ==="
  echo ""
  echo "Q: Conda 환경이 활성화되지 않아요"
  echo "A: source ~/.bashrc 실행 후 다시 시도하세요"
  echo ""
  echo "Q: 패키지 설치가 Permission Denied 오류로 실패해요"
  echo "A: conda 환경 내에서 설치하세요 (conda activate myenv)"
  echo ""
  echo "Q: 디스크가 꽉 찼어요"
  echo "A: 캐시 정리 메뉴에서 불필요한 캐시를 정리하세요"
  echo ""
  echo "Q: 홈 디렉토리 심볼릭 링크가 깨졌어요"
  echo "A: 관리자에게 문의하세요"
  echo ""
  echo "=== 관리자 문의 ==="
  echo "이메일: eungbean@homilabs.ai"
  echo "조직: HOMI AI"
  echo ""
  echo "=== 추가 문서 ==="
  echo "- README.md (한국어)"
  echo "- README_eng.md (영어)"
  echo "- AGENTS.md (개발자용)"
  echo ""
  read -p "Enter를 눌러 계속..."
}

show_text_menu() {
  while true; do
    show_header
    echo "[메뉴]"
    echo ""
    echo "1. 환경 정보 확인"
    echo "2. 디스크 사용량 확인"
    echo "3. 캐시 정리"
    echo "4. Conda 환경 관리 가이드"
    echo "5. 패키지 설치 가이드"
    echo "6. 도움말"
    echo "7. 종료"
    echo ""
    
    read -p "선택 [1-7]: " choice
    
    case $choice in
      1) show_environment_info ;;
      2) show_disk_usage ;;
      3) clean_cache_menu ;;
      4) show_conda_guide ;;
      5) show_package_guide ;;
      6) show_help ;;
      7) 
        show_header
        echo "AICADataKeeper를 이용해 주셔서 감사합니다."
        echo ""
        exit 0
        ;;
      *)
        echo "잘못된 선택입니다. 다시 선택해주세요."
        sleep 1
        ;;
    esac
  done
}

show_dialog_menu() {
  while true; do
    CHOICE=$($DIALOG_CMD --clear --backtitle "AICADataKeeper" \
      --title "[ 사용자 메뉴 ]" \
      --menu "작업을 선택하세요:" 15 60 7 \
      1 "환경 정보 확인" \
      2 "디스크 사용량 확인" \
      3 "캐시 정리" \
      4 "Conda 환경 관리 가이드" \
      5 "패키지 설치 가이드" \
      6 "도움말" \
      7 "종료" \
      3>&1 1>&2 2>&3)
    
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -ne 0 ]; then
      clear
      echo "AICADataKeeper를 이용해 주셔서 감사합니다."
      exit 0
    fi
    
    case $CHOICE in
      1) show_environment_info ;;
      2) show_disk_usage ;;
      3) clean_cache_menu ;;
      4) show_conda_guide ;;
      5) show_package_guide ;;
      6) show_help ;;
      7)
        clear
        echo "AICADataKeeper를 이용해 주셔서 감사합니다."
        exit 0
        ;;
    esac
  done
}

if [ "$1" == "--help" ]; then
  echo "사용법: $0"
  echo ""
  echo "AICADataKeeper 사용자 인터랙티브 터미널"
  echo ""
  echo "옵션:"
  echo "  --help    이 도움말 출력"
  echo ""
  exit 0
fi

if [ "$DIALOG_CMD" != "text" ]; then
  show_dialog_menu
else
  show_text_menu
fi
