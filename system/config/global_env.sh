#!/bin/bash
# /data/system/shared_envs.sh
# 모든 사용자를 위한 공통 환경 변수 설정 파일

# 캐시 경로 설정
export SYSTEM_CACHE_DIR="/data/system/cache"
export PIP_CACHE_DIR="/data/system/cache/pip"
export CONDA_PKGS_DIRS="/data/system/cache/conda/pkgs"
export npm_config_cache="/data/system/cache/npm"
export YARN_CACHE_FOLDER="/data/system/cache/yarn"
export PYTHONUSERBASE="/data/system/cache/python"
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