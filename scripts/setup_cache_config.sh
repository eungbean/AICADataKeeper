#!/bin/bash
# Setup package manager configuration files for hybrid cache strategy
# This script creates system-wide config files that work in all contexts (systemd, cron, sudo)
# 
# Usage: sudo ./setup_cache_config.sh
#
# Creates:
#   - /etc/conda/.condarc (conda package cache)
#   - /etc/pip.conf (pip package cache)
#   - /etc/npmrc (npm package cache)

set -e

# Root privilege check
if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script requires root privileges."
  echo "[ERROR] Usage: sudo $0"
  exit 1
fi

echo "[INFO] Setting up package manager configuration files..."

# ============================================================================
# 1. Conda Configuration (/etc/conda/.condarc)
# ============================================================================
CONDA_CONFIG_DIR="/etc/conda"
CONDA_CONFIG_FILE="$CONDA_CONFIG_DIR/.condarc"

if [ -f "$CONDA_CONFIG_FILE" ]; then
  echo "[INFO] $CONDA_CONFIG_FILE already exists. Skipping conda config."
else
  echo "[INFO] Creating $CONDA_CONFIG_FILE..."
  mkdir -p "$CONDA_CONFIG_DIR"
  
  cat > "$CONDA_CONFIG_FILE" << 'EOF'
# System-wide conda configuration
# Package cache directory (shared across all users)
pkgs_dirs:
  - /data/cache/conda/pkgs
EOF
  
  chmod 644 "$CONDA_CONFIG_FILE"
  echo "[INFO] Conda configuration created successfully."
fi

# ============================================================================
# 2. Pip Configuration (/etc/pip.conf)
# ============================================================================
PIP_CONFIG_FILE="/etc/pip.conf"

if [ -f "$PIP_CONFIG_FILE" ]; then
  echo "[INFO] $PIP_CONFIG_FILE already exists. Skipping pip config."
else
  echo "[INFO] Creating $PIP_CONFIG_FILE..."
  
  cat > "$PIP_CONFIG_FILE" << 'EOF'
# System-wide pip configuration
[global]
cache-dir = /data/cache/pip
EOF
  
  chmod 644 "$PIP_CONFIG_FILE"
  echo "[INFO] Pip configuration created successfully."
fi

# ============================================================================
# 3. NPM Configuration (/etc/npmrc)
# ============================================================================
NPM_CONFIG_FILE="/etc/npmrc"

if [ -f "$NPM_CONFIG_FILE" ]; then
  echo "[INFO] $NPM_CONFIG_FILE already exists. Skipping npm config."
else
  echo "[INFO] Creating $NPM_CONFIG_FILE..."
  
  cat > "$NPM_CONFIG_FILE" << 'EOF'
# System-wide npm configuration
cache=/data/cache/npm
EOF
  
  chmod 644 "$NPM_CONFIG_FILE"
  echo "[INFO] NPM configuration created successfully."
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "[INFO] ============================================"
echo "[INFO] Cache configuration setup complete!"
echo "[INFO] ============================================"
echo "[INFO] Created configuration files:"
[ -f "$CONDA_CONFIG_FILE" ] && echo "[INFO]   - $CONDA_CONFIG_FILE"
[ -f "$PIP_CONFIG_FILE" ] && echo "[INFO]   - $PIP_CONFIG_FILE"
[ -f "$NPM_CONFIG_FILE" ] && echo "[INFO]   - $NPM_CONFIG_FILE"
echo ""
echo "[INFO] These config files work in all contexts:"
echo "[INFO]   - Interactive shells"
echo "[INFO]   - systemd services"
echo "[INFO]   - cron jobs"
echo "[INFO]   - sudo commands"
echo ""
echo "[INFO] Environment variables in /etc/profile.d/global_envs.sh"
echo "[INFO] provide additional override capability for users."
echo "[INFO] ============================================"
