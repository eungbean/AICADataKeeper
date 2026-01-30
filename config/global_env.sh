#!/bin/bash
# /data/config/global_env.sh
# 모든 사용자를 위한 공통 환경 변수 설정 파일
#
# 하이브리드 캐시 전략:
# - 공유: AI 모델 (HF, Torch) - 대용량, 읽기전용
# - 공유: Conda 패키지 - Conda가 공유 잘 지원
# - 개인: pip/uv/npm/yarn - 권한 충돌 방지 (기본 ~/.cache 사용)

# Conda 공유 캐시 (Conda는 공유 잘 지원)
export CONDA_PKGS_DIRS="/data/cache/conda/pkgs"
export CONDA_ENVS_PATH="$HOME/conda/envs"

# AI 모델 공유 캐시 (대용량, 읽기전용, 공유 이점 큼)
export MODELS_DIR="/data/models"
export TORCH_HOME="/data/models/torch"
export HF_HOME="/data/models/huggingface"
export HF_HUB_CACHE="/data/models/huggingface/hub"
export HF_DATASETS_CACHE="/data/models/huggingface/datasets"
export COMFYUI_HOME="/data/models/comfyui"
export FLUX_HOME="/data/models/flux"

# 기타 공유 경로
export DATASET_DIR="/data/dataset"

# Bun (NFS 홈 환경 호환)
# - BUN_INSTALL_CACHE_DIR: 캐시를 로컬 디스크로 두어 BunInstallFailedError 방지 (BUN_REPORT.md 참고)
# - PATH: 사용자가 ~/.bun/bin에 Bun을 설치한 경우 자동으로 인식
export BUN_INSTALL_CACHE_DIR="${BUN_INSTALL_CACHE_DIR:-/tmp/bun-install-cache-$USER}"
export PATH="$HOME/.bun/bin:$PATH"

# 참고: pip, uv, npm, yarn 캐시는 설정하지 않음
# → 기본값 ~/.cache 사용 (이미 /data/users/$USER/.cache에 있음)
# → 사용자별 격리로 권한 충돌 방지
# Opencode CLI (글로벌 설치)
export PATH="/data/apps/opencode/bin:$PATH"
