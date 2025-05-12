#!/bin/bash
# [07] 캐시 정리 스크립트
# 역할: 다양한 캐시 디렉토리를 정리하여 디스크 공간 확보

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] 이 스크립트는 root 권한으로 실행해야 합니다."
  echo "[ERROR] 사용법: sudo $0 [--all|--conda|--pip|--torch]"
  exit 1
fi

# 캐시 경로 설정
MINICONDA_PATH="/data/system/apps/miniconda3"
CONDA_CACHE="/data/cache/conda/pkgs"
PIP_CACHE="/data/cache/pip"
TORCH_CACHE="/data/models/torch"
HF_CACHE="/data/models/huggingface"

# 도움말 표시
function show_help {
  echo "사용법: sudo $0 [옵션]"
  echo "옵션:"
  echo "  --all     모든 캐시 정리"
  echo "  --conda   Conda 패키지 캐시 정리"
  echo "  --pip     Pip 패키지 캐시 정리"
  echo "  --torch   PyTorch 모델 캐시 정리"
  echo "  --hf      HuggingFace 캐시 정리"
  echo "  --help    이 도움말 표시"
}

# Conda 캐시 정리
function clean_conda_cache {
  echo "[INFO] Conda 캐시 정리 중..."
  if [ -d "$CONDA_CACHE" ]; then
    $MINICONDA_PATH/bin/conda clean --all --yes || {
      echo "[ERROR] Conda 캐시 정리 실패"
      return 1
    }
    echo "[INFO] Conda 캐시 정리 완료"
  else
    echo "[INFO] Conda 캐시 디렉토리가 없습니다: $CONDA_CACHE"
  fi
  return 0
}

# Pip 캐시 정리
function clean_pip_cache {
  echo "[INFO] Pip 캐시 정리 중..."
  if [ -d "$PIP_CACHE" ]; then
    rm -rf "$PIP_CACHE"/* || {
      echo "[ERROR] Pip 캐시 정리 실패"
      return 1
    }
    echo "[INFO] Pip 캐시 정리 완료"
  else
    echo "[INFO] Pip 캐시 디렉토리가 없습니다: $PIP_CACHE"
  fi
  return 0
}

# PyTorch 캐시 정리
function clean_torch_cache {
  echo "[INFO] PyTorch 캐시 정리 중..."
  if [ -d "$TORCH_CACHE" ]; then
    rm -rf "$TORCH_CACHE/hub"/* || {
      echo "[ERROR] PyTorch 캐시 정리 실패"
      return 1
    }
    echo "[INFO] PyTorch 캐시 정리 완료"
  else
    echo "[INFO] PyTorch 캐시 디렉토리가 없습니다: $TORCH_CACHE"
  fi
  return 0
}

# HuggingFace 캐시 정리
function clean_hf_cache {
  echo "[INFO] HuggingFace 캐시 정리 중..."
  if [ -d "$HF_CACHE" ]; then
    rm -rf "$HF_CACHE/.cache"/* || {
      echo "[WARNING] HuggingFace 캐시 일부 정리 실패"
    }
    echo "[INFO] HuggingFace 캐시 정리 완료"
  else
    echo "[INFO] HuggingFace 캐시 디렉토리가 없습니다: $HF_CACHE"
  fi
  return 0
}

# 인자가 없으면 도움말 표시
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

# 옵션 처리
case "$1" in
  --all)
    clean_conda_cache
    clean_pip_cache
    clean_torch_cache
    clean_hf_cache
    ;;
  --conda)
    clean_conda_cache
    ;;
  --pip)
    clean_pip_cache
    ;;
  --torch)
    clean_torch_cache
    ;;
  --hf)
    clean_hf_cache
    ;;
  --help)
    show_help
    exit 0
    ;;
  *)
    echo "[ERROR] 알 수 없는 옵션: $1"
    show_help
    exit 1
    ;;
esac

echo "[INFO] 캐시 정리 작업 완료"