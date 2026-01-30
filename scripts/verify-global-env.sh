#!/bin/bash

set -e

ERRORS=0

check_var() {
    local var_name="$1"
    local var_value="${!var_name}"
    local required="${2:-true}"
    
    if [ -z "$var_value" ]; then
        if [ "$required" = "true" ]; then
            echo "✗ FAIL: $var_name is not set"
            ((ERRORS++))
        else
            echo "○ SKIP: $var_name is not set (optional)"
        fi
        return
    fi
    
    if [ -d "$var_value" ]; then
        echo "✓ PASS: $var_name = $var_value"
    else
        echo "✗ FAIL: $var_name = $var_value (directory does not exist)"
        ((ERRORS++))
    fi
}

GLOBAL_ENV_FILE="/data/config/global_env.sh"
if [ -f "$GLOBAL_ENV_FILE" ]; then
    echo "[INFO] Loading environment from $GLOBAL_ENV_FILE"
    source "$GLOBAL_ENV_FILE"
else
    echo "✗ FAIL: Global environment file $GLOBAL_ENV_FILE not found"
    exit 1
fi

echo ""
echo "=== Verifying Global Environment Variables ==="

check_var "CONDA_PKGS_DIRS" "true"
check_var "HF_HOME" "true"
check_var "HF_HUB_CACHE" "true"
check_var "HF_DATASETS_CACHE" "true"
check_var "TORCH_HOME" "true"
check_var "MODELS_DIR" "true"
check_var "DATASET_DIR" "true"

check_var "COMFYUI_HOME" "false"
check_var "FLUX_HOME" "false"

if [ -n "$CONDA_ENVS_PATH" ]; then
    echo "✓ PASS: CONDA_ENVS_PATH = $CONDA_ENVS_PATH (per-user path)"
else
    echo "✗ FAIL: CONDA_ENVS_PATH is not set"
    ((ERRORS++))
fi

if [ -n "$BUN_INSTALL_CACHE_DIR" ]; then
    echo "✓ PASS: BUN_INSTALL_CACHE_DIR = $BUN_INSTALL_CACHE_DIR (user-specific cache)"
else
    echo "○ SKIP: BUN_INSTALL_CACHE_DIR is not set (optional)"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "✓ All required environment variables are properly set and paths exist."
    exit 0
else
    echo "✗ $ERRORS environment variable check(s) failed."
    exit 1
fi