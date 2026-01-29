# Scripts Directory - Execution Flow Reference

**Generated:** 2026-01-29 12:51  
**Commit:** `5f8e1f9`  
**Branch:** `main`

## Overview

16 bash scripts implementing GPU server environment automation. Numbered scripts (1-5) = dependency chain. Named scripts = orchestrators/utilities.

## Execution Patterns

### Numbered Pipeline (1-5)
```
1_install_miniconda3_global.sh  → Global Miniconda install
2_install_global_env.sh         → /etc/profile.d/global_envs.sh setup
3_create_user_data_dir.sh       → /home/<user> → /data/users/<user> symlink
4_setup_user_conda.sh           → User .condarc + conda init
5_fix_user_permission.sh        → chown user:group recursively
```

**Critical Order**: 1→2 for global, 3→4→5 for per-user. Breaking order = script failures.

### Orchestrators (Call Other Scripts)
- `setup_global_after_startup.sh` → Calls 1, 2 (post-reboot recovery)
- `setup_new_user.sh` → Calls 3, 4, 5 (user onboarding/recovery)
- `auto_recovery.sh` → Calls setup_global + setup_new_user for each user in users.txt
- `setup_wizard.sh` → Interactive menu calling all setup scripts

### Utilities (Standalone)
- `register_user.sh` → Add to users.txt (auto-recovery registry)
- `clean_cache.sh` → Cleanup conda/pip/torch/hf caches
- `disk_alert.sh` → Monitor /data partition usage
- `setup_permissions.sh` → Apply ACL to shared directories
- `setup_sudoers.sh` → Configure selective NOPASSWD for gpu-users
- `setup_cache_config.sh` → Create /etc/{conda/.condarc,pip.conf,npmrc}
- `setup_uv.sh` → Install uv package manager

## Entry Points

| User Type | Command | Purpose |
|-----------|---------|---------|
| **Admin (interactive)** | `sudo setup_wizard.sh` | TUI menu for all tasks |
| **Admin (post-reboot)** | `sudo setup_global_after_startup.sh` | Restore global environment |
| **Admin (new user)** | `sudo setup_new_user.sh <user> <group>` | Onboard user |
| **Admin (register user)** | `sudo register_user.sh <user> <group>` | Add to auto-recovery |
| **User** | `sudo clean_cache.sh --all` | Clean shared caches |
| **User** | `sudo disk_alert.sh --threshold 90` | Check disk usage |
| **Systemd** | `auto_recovery.sh` | Automatic recovery after reboot |

## Critical Dependencies

```
Script 2 REQUIRES:
- /data/config/global_env.sh exists
- FAILS if missing

Script 4 REQUIRES:
- Miniconda installed (/data/apps/miniconda3/)
- /data/users/<user> exists (script 3 creates it)
- FAILS if either missing

Scripts 4 & 5 REQUIRE:
- User data directory (/data/users/<user>) exists
- script 3 MUST run first
```

## Script Conventions

### All Scripts Follow:
```bash
#!/bin/bash
# [NN] Description in Korean
# 역할: Role description

set -e  # Exit on error

if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script requires root privileges."
  exit 1
fi
```

### Error Messages:
- `[ERROR]` = critical failures
- `[INFO]` = progress updates
- `[WARNING]` = non-critical issues

### Idempotency:
All scripts check before create/modify:
```bash
if [ ! -d "$TARGET" ]; then
  mkdir -p "$TARGET"
fi
```

## Non-Obvious Patterns

### Numbered Script Meaning
- `[01]` = Global system (run once per server)
- `[02]` = Global config (run once per server)
- `[03]` = Per-user data (run per user)
- `[04]` = Per-user config (run per user)
- `[05]` = Per-user cleanup (run per user)
- `[00]` = Wrapper/orchestrator
- `[06-1]`, `[06-2]` = Recovery system (registry + orchestrator)
- `[07]` = Utilities

### Wrapper vs. Atomic
**Wrappers** (call other scripts):
- setup_global_after_startup.sh
- setup_new_user.sh
- auto_recovery.sh
- setup_wizard.sh

**Atomic** (standalone, no script calls):
- All numbered scripts (1-5)
- All utility scripts

### Script Directory Reference
All scripts use:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/3_create_user_data_dir.sh" "$USERNAME" "$GROUPNAME"
```

## Permission Model

**NEVER use `chmod 777`**. Use ACL:
```bash
setfacl -d -m g:gpu-users:rwx /path  # Default for new files
chmod 2775 /path                      # setgid for group inheritance
```

Standard permissions:
- Shared caches: `2775` + ACL
- User homes: `750` (user:group)
- Scripts: `755` (root:root)

## Sudoers Pattern

File: `/etc/sudoers.d/aica-datakeeper`

```bash
Cmnd_Alias CACHE_MGMT = /data/scripts/clean_cache.sh
Cmnd_Alias DISK_CHECK = /usr/bin/df
%gpu-users ALL=(ALL) NOPASSWD: CACHE_MGMT, DISK_CHECK
```

**Never** `NOPASSWD: ALL` — only specific commands.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Script 2 fails | global_env.sh missing | Ensure ../config/global_env.sh exists |
| Script 4 fails | Miniconda not installed | Run script 1 first |
| Script 4/5 fails | User data missing | Run script 3 first |
| setup_sudoers fails | Group missing | Run setup_permissions.sh first |
| auto_recovery partial | User doesn't exist | Remove from users.txt or create user |

## Verification

```bash
# Syntax check all scripts
bash -n *.sh

# Test idempotency (run twice)
sudo ./setup_new_user.sh testuser gpu-users
sudo ./setup_new_user.sh testuser gpu-users  # Should not fail

# Verify ACL applied
getfacl /data/cache/pip | grep "group:gpu-users:rwx"

# Verify sudoers syntax
visudo -c -f /etc/sudoers.d/aica-datakeeper
```

## Notes

- Numbered scripts not meant for direct execution (called by wrappers)
- All scripts must be idempotent (safe to run multiple times)
- Script 3 backs up existing directories before symlinking
- auto_recovery.sh reads users.txt line-by-line (format: `username:groupname`)
- setup_wizard.sh supports dialog/whiptail/text fallback (auto-detects)
