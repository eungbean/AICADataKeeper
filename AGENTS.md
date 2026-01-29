# AICADataKeeper - GPU Server Environment Manager

## Project Overview

AICADataKeeper is a multi-user GPU server environment management system designed for NHN Cloud AI infrastructure. It solves the critical challenge of managing volatile 200GB SSD with persistent 70TB HDD storage through symbolic links and shared cache architecture.

**Core Problem**: GPU servers with limited SSD capacity (200GB) that resets on reboot, requiring efficient use of persistent HDD storage (50TB + 20TB) for user data, package caches, and AI model storage.

**Solution**: Automated user environment setup with:
- Symbolic links from `/home/username` to `/data/users/username` (persistent storage)
- Shared package caches (conda, pip, npm, yarn) to avoid duplication
- Centralized AI model storage (PyTorch, HuggingFace, ComfyUI, Flux)
- ACL-based permission management for secure multi-user access
- Automated recovery after system reboots

**Target Users**: 4-10 member teams sharing GPU resources in research/development environments.

---

## Tech Stack

### Core Technologies
- **Shell Scripting**: Bash (all automation scripts)
- **Init System**: systemd (auto-recovery service)
- **Package Managers**: 
  - Conda/Miniconda (primary Python environment manager)
  - uv (fast pip alternative, optional)
- **Permission Management**: 
  - ACL (setfacl/getfacl) for fine-grained access control
  - sudoers for selective privilege escalation

### Infrastructure
- **OS**: Linux (Ubuntu/CentOS compatible)
- **Storage**: 
  - SSD 200GB (volatile, resets on reboot) - system only
  - HDD 50TB (persistent) - mounted at `/data` - user data, caches, models
  - HDD 20TB (backup) - mounted at `/backup`
- **Filesystem**: ext4/xfs with ACL support required

---

## Project Structure

```
/data/
├── system/                     # System management
│   ├── config/
│   │   ├── global_env.sh       # Global environment variables
│   │   └── users.txt           # Registered users for auto-recovery
│   ├── scripts/
│   │   ├── install-miniconda.sh     # Install shared Miniconda
│   │   ├── install-global-env.sh            # Setup system environment
│   │   ├── user-create-home.sh          # Create user home symlinks
│   │   ├── user-setup-conda.sh              # User conda configuration
│   │   ├── user-fix-permissions.sh           # Fix file ownership
│   │   ├── user-setup.sh                  # User onboarding wrapper
│   │   ├── ops-setup-global.sh      # Post-reboot global recovery
│   │   ├── system-permissions.sh               # Apply ACL permissions
│   │   ├── system-sudoers.sh                   # Configure sudoers
│   │   ├── install-uv.sh                        # Install uv package manager
│   │   ├── ops-recovery.sh                   # Systemd recovery script
│   │   ├── user-register.sh                   # Add user to registry
│   │   ├── ops-disk-alert.sh                      # Disk usage monitoring
│   │   └── ops-clean-cache.sh                     # Cache cleanup utility
│   ├── cache/                  # Shared package caches
│   │   ├── conda/pkgs/         # Conda packages
│   │   ├── pip/                # Pip packages
│   │   ├── npm/                # NPM packages
│   │   ├── yarn/               # Yarn packages
│   │   ├── python/             # Python user-installed packages
│   │   └── uv/                 # uv cache
│   └── apps/
│       └── miniconda3/         # Shared Miniconda installation
├── models/                     # AI model caches
│   ├── torch/                  # PyTorch Hub models
│   ├── huggingface/            # HuggingFace models & datasets
│   ├── comfyui/                # ComfyUI models
│   └── flux/                   # Flux models
├── users/                      # User home directories
│   └── <username>/             # Individual user home (target of /home/<username> symlink)
├── dataset/                    # Shared datasets
└── code/                       # Shared code repositories

/etc/
├── profile.d/
│   └── global_envs.sh          # System-wide environment loader
└── sudoers.d/
    └── aica-datakeeper         # Custom sudoers rules

/etc/systemd/system/
└── aica-recovery.service       # Auto-recovery service
```

---

## Development Guidelines

### Script Conventions

All scripts follow these patterns:

1. **Shebang and Set Options**:
   ```bash
   #!/bin/bash
   set -e  # Exit on error
   ```

2. **Root Privilege Check**:
   ```bash
   if [ "$(id -u)" -ne 0 ]; then
     echo "[ERROR] This script requires root privileges."
     echo "[ERROR] Usage: sudo $0 [args]"
     exit 1
   fi
   ```

3. **Error Messages**:
   - Errors: `[ERROR] message`
   - Info: `[INFO] message`
   - Warnings: `[WARNING] message`

4. **Idempotency**: All scripts can be run multiple times safely. Check before create/modify.

5. **Input Validation**: Always validate username, groupname, paths before operations.

### Permission Model

**DO NOT use `chmod 777`**. Use ACL instead:

```bash
# Set group permissions with ACL
setfacl -m g:gpu-users:rwx /path/to/shared
setfacl -d -m g:gpu-users:rwx /path/to/shared  # Default for new files

# Set setgid bit for group inheritance
chmod g+s /path/to/shared
```

**Standard Permissions**:
- Shared caches: `2775` (drwxrwsr-x) with ACL for gpu-users:rwx
- User homes: `750` (drwxr-x---) owned by user:group
- Scripts: `755` (rwxr-xr-x) owned by root:root

### Sudoers Rules

Only grant specific commands, never `NOPASSWD: ALL`:

```bash
# /etc/sudoers.d/aica-datakeeper
Cmnd_Alias CACHE_MGMT = /data/scripts/ops-clean-cache.sh
Cmnd_Alias DISK_CHECK = /usr/bin/df
%gpu-users ALL=(ALL) NOPASSWD: CACHE_MGMT, DISK_CHECK
```

### Environment Variables

Global environment variables defined in `/data/config/global_env.sh`:

```bash
# Cache paths
export SYSTEM_CACHE_DIR="/data/cache"
export PIP_CACHE_DIR="/data/cache/pip"
export CONDA_PKGS_DIRS="/data/cache/conda/pkgs"
export UV_CACHE_DIR="/data/cache/uv"

# AI model paths
export TORCH_HOME="/data/models/torch"
export HF_HOME="/data/models/huggingface"
export TRANSFORMERS_CACHE="/data/models/huggingface/transformers"
export HF_DATASETS_CACHE="/data/models/huggingface/datasets"
```

Loaded system-wide via `/etc/profile.d/global_envs.sh`.

---

## Key Patterns

### User Onboarding Flow

```bash
# 1. Create Linux user
sudo adduser <username>
sudo usermod -aG gpu-users <username>

# 2. Setup user environment (automated)
sudo /data/scripts/user-setup.sh <username> gpu-users

# 3. Register for auto-recovery
sudo /data/scripts/user-register.sh <username> gpu-users

# Result:
# - /home/<username> -> /data/users/<username> (symlink)
# - User conda environment configured
# - Proper permissions applied
# - User added to auto-recovery registry
```

### Post-Reboot Recovery

```bash
# Automatic (via systemd service)
systemctl start aica-recovery.service

# Manual (if needed)
sudo /data/scripts/ops-recovery.sh
```

Recovery sequence:
1. Install/verify Miniconda at `/data/apps/miniconda3`
2. Setup global environment variables at `/etc/profile.d/global_envs.sh`
3. Create/restore cache directories with proper permissions
4. For each registered user in `/data/config/users.txt`:
   - Restore home directory symlink
   - Restore conda configuration
   - Fix file permissions

### Cache Cleanup

```bash
# Clean all caches
sudo /data/scripts/ops-clean-cache.sh --all

# Clean specific caches
sudo /data/scripts/ops-clean-cache.sh --conda
sudo /data/scripts/ops-clean-cache.sh --pip
sudo /data/scripts/ops-clean-cache.sh --torch
sudo /data/scripts/ops-clean-cache.sh --hf
```

### Disk Monitoring

```bash
# Manual check
/data/scripts/ops-disk-alert.sh --threshold 80 --dry-run

# Automated (via cron)
# Add to /etc/cron.hourly/ or root crontab:
0 * * * * /data/scripts/ops-disk-alert.sh --threshold 80
```

---

## Testing Strategy

### Script Validation

All scripts must pass syntax check:
```bash
bash -n /data/scripts/*.sh
```

### Acceptance Criteria

Each feature has verification commands (see `.sisyphus/plans/aica-improvement.md`):

**Example - Permission Setup**:
```bash
# Verify ACL
getfacl /data/cache/pip | grep "default:group:gpu-users:rwx"
# Expected: match found

# Verify setgid
ls -ld /data/cache/pip | grep "^d.*s"
# Expected: 's' or 'S' in group execute position

# Test non-admin cache access
sudo -u testuser sudo -n /data/scripts/ops-clean-cache.sh --help
# Expected: exit code 0 (NOPASSWD works)
```

### Manual Testing Checklist

After deployment:
- [ ] New user can create conda environment without sudo
- [ ] Non-admin user can run `sudo ops-clean-cache.sh`
- [ ] uv creates cache at `$UV_CACHE_DIR`
- [ ] After reboot, all registered users' environments restored
- [ ] Disk alert triggers at threshold

---

## Deployment

### Initial Setup (Fresh Server)

```bash
# 1. Clone repository to persistent storage
cd /data
git clone <repo-url> AICADataKeeper
cd AICADataKeeper

# 2. Make scripts executable
chmod +x scripts/*.sh

# 3. Run global setup
sudo ./scripts/ops-setup-global.sh gpu-users

# 4. Setup permissions
sudo ./scripts/system-permissions.sh
sudo ./scripts/system-sudoers.sh

# 5. Install uv (optional)
sudo ./scripts/install-uv.sh

# 6. Enable auto-recovery service
sudo systemctl enable --now aica-recovery.service

# 7. Setup disk monitoring (optional)
echo '0 * * * * /data/scripts/ops-disk-alert.sh --threshold 80' | sudo crontab -
```

### User Addition

```bash
# Standard user onboarding
sudo adduser alice
sudo usermod -aG gpu-users alice
sudo /data/scripts/user-setup.sh alice gpu-users
sudo /data/scripts/user-register.sh alice gpu-users
```

### Migration from Old Setup

If migrating from chmod 777 setup:

```bash
# 1. Backup current permissions
getfacl -R /data > /backup/acl-backup-$(date +%Y%m%d).txt

# 2. Apply new permission model
sudo /data/scripts/system-permissions.sh

# 3. Verify no breakage
# Test conda/pip installations for existing users

# 4. Rollback if needed
# setfacl --restore=/backup/acl-backup-YYYYMMDD.txt
```

---

## Important Context

### Known Issues (as of 2026-01-29)

**Fixed in Improvement Plan**:
- ~~`ops-setup-global.sh` undefined variable `$ENV_DST`~~ → FIXED
- ~~Cache path inconsistency (`/data/cache/` vs `/data/cache/`)~~ → FIXED
- ~~chmod 777 security issues~~ → REPLACED with ACL
- ~~No auto-recovery service~~ → ADDED systemd service

### Constraints

**DO NOT**:
- Modify `/data/users/*/` content (only permissions)
- Remove existing conda base environment
- Add package managers other than uv (no pixi, poetry, pdm)
- Implement web UI/dashboard (scope: CLI only)
- Change symlink architecture (`/home/<user>` → `/data/users/<user>`)

**MUST**:
- Preserve all existing user data during upgrades
- Maintain conda compatibility
- Keep scripts idempotent
- Verify ACL support before applying (`mount | grep /data` should show `acl` option)

### Directory Naming Convention

- System directories: lowercase with underscore (`user_data`, `conda_pkgs`)
- Config files: snake_case with `.sh` extension
- User-facing scripts: descriptive names (`user-setup.sh`, not `setup.sh`)
- Numbered scripts: prefix for execution order (`1_install_`, `2_install_`)

### Performance Considerations

- **Cache Size**: Monitor `/data/cache/` - can grow to 10s of GB
- **Model Size**: HuggingFace models can be 5-20GB each
- **Disk I/O**: Multiple users downloading simultaneously = bottleneck
- **Recommendation**: Use `ionice` for large operations during peak hours

### Security Notes

- Shared caches accessible to all users in `gpu-users` group
- Users can potentially install malicious packages to shared cache
- Mitigation: Regular cache audits, user training on trusted sources
- Logged commands via sudoers help with audit trails

### Troubleshooting

**Symlink Broken**:
```bash
sudo /data/scripts/user-create-home.sh <username> gpu-users
```

**Permission Denied on Cache**:
```bash
sudo /data/scripts/system-permissions.sh
# or
sudo chmod 2775 /data/cache/<specific-cache>
sudo setfacl -m g:gpu-users:rwx /data/cache/<specific-cache>
```

**Conda Environment Not Found**:
```bash
sudo /data/scripts/user-setup-conda.sh <username> gpu-users
```

**Service Failed to Start**:
```bash
journalctl -u aica-recovery.service -n 50
# Check /data/scripts/ops-recovery.sh logs
```

---

## Maintenance

### Regular Tasks

**Weekly**:
- Monitor disk usage: `df -h /data`
- Review disk alert logs: `/var/log/aica-disk-alert.log`

**Monthly**:
- Clean unused caches: `sudo /data/scripts/ops-clean-cache.sh --all`
- Review user list: `cat /data/config/users.txt`
- Check for obsolete user data: `ls /data/users/`

**Quarterly**:
- Backup critical data: `rsync -av /data/users/ /backup/users/`
- Update Miniconda: Coordinate with all users first
- Review ACL policies: `getfacl /data/cache/*`

### Upgrade Path

When new scripts are added:
1. Pull latest changes: `cd /data/system && git pull`
2. Review changelog/commits
3. Test in isolated environment if possible
4. Apply changes: `chmod +x /data/scripts/*.sh`
5. Verify: Run with `--dry-run` flags where available

---

## Related Documentation

- [README.md](README.md) - User-facing documentation (Korean)
- [README_eng.md](README_eng.md) - User-facing documentation (English)
- [.sisyphus/plans/aica-improvement.md](.sisyphus/plans/aica-improvement.md) - Current improvement work plan
- [LICENSE](LICENSE) - MIT License

---

## Contact & Support

**Author**: Eungbean Lee  
**Email**: eungbean@homilabs.ai  
**Organization**: HOMI AI  
**Version**: 1.0.0 → 2.0.0 (in progress)

**Contribution**: See improvement plan in `.sisyphus/plans/` for ongoing work. Pull requests welcome for bug fixes and enhancements.