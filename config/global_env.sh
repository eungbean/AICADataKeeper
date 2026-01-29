#!/bin/bash
# /data/config/global_env.sh
# 모든 사용자를 위한 공통 환경 변수 설정 파일

# 캐시 경로 설정
export SYSTEM_CACHE_DIR="/data/cache"
export PIP_CACHE_DIR="/data/cache/pip"
export CONDA_PKGS_DIRS="/data/cache/conda/pkgs"
export CONDA_ENVS_PATH="$HOME/conda/envs"
export UV_CACHE_DIR="/data/cache/uv"
export npm_config_cache="/data/cache/npm"
export YARN_CACHE_FOLDER="/data/cache/yarn"
# AI 관련 캐시
export MODELS_DIR="/data/models"
export TORCH_HOME="/data/models/torch"
export HF_HOME="/data/models/huggingface"
export TRANSFORMERS_CACHE="/data/models/huggingface/transformers"
export HF_DATASETS_CACHE="/data/models/huggingface/datasets"
export COMFYUI_HOME="/data/models/comfyui"
export FLUX_HOME="/data/models/flux"

# 기존 경로 호환성 유지
export DATASET_DIR="/data/dataset"