# 🚀 AICADataKeeper: NHN CLOUD AI Environment Manager

[![KR](https://img.shields.io/badge/lang-한국어-red.svg)](README.md)
[![EN](https://img.shields.io/badge/lang-English-blue.svg)](README_eng.md)

> Author: Eungbean Lee  
> Email: ian@homilabs.ai  
> Organization: HOMI AI Inc.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/eungbean/aica-nhn-environment-manager)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-brightgreen.svg)](https://github.com/eungbean/aica-nhn-environment-manager)

## 🤔 Why is this environment needed?

NHN Cloud AI servers have two important characteristics:

1. **Small and volatile SSD**: The default disk (SSD) is only 200GB and **all data is reset** when the server restarts.
2. **Persistent storage on high-capacity drives**: The server has 70TB (50TB + 20TB) of high-capacity HDDs mounted at `/data` and `/backup` paths where data can be stored permanently.

In this environment, it's efficient to store all user work data in persistent storage and centrally manage packages and models that are used in common.

## ⚙️ How does it work?

This project provides the following core features:

- 🔗 **Home directory linking**: User home directories (`/home/username`) are automatically linked to persistent storage (`/data/users/username`).
- 📦 **Integrated package management**: Conda, Pip, and other packages are centrally managed to save disk space.
- 🧠 **Model cache sharing**: AI model files are shared to prevent duplicate downloads.
- 🤖 **Automated setup**: User addition and environment configuration are automated with scripts.

## 📂 Directory Structure

```
/data/
  ├── dataset/                  # Shared dataset repository
  ├── code/                     # Shared code repository
  ├── models/                   # AI model and cache repository
  │   ├── huggingface/          # HuggingFace models/cache
  │   ├── torch/                # PyTorch models/cache
  │   └── ...
  ├── users/                    # User home directories
  │   ├── username/             # Individual user home directory
  │   └── ...
  ├── cache/                    # Integrated package cache management
  │   ├── conda/                # conda package cache
  │   ├── pip/                  # pip package cache
  │   └── ...
  └── system/                   # System management
      ├── scripts/              # Management scripts
      ├── config/               # Environment configuration files
      └── apps/                 # Shared applications
```

## 🚀 Getting Started

### 📥 Installing the Environment Manager

```bash
# 1. Go to the system directory
cd /data

# 2. Clone the repository
git clone https://github.com/eungbean/aica-nhn-environment-manager system

# 3. Set script permissions
chmod +x /data/scripts/*.sh
```

### 🗂️ Cache Strategy: Hybrid Approach

AICADataKeeper uses a **Config Files + Environment Variables** hybrid strategy for efficient cache management.

#### System Config Files
- `/etc/conda/.condarc`: Conda package cache path
- `/etc/pip.conf`: Pip package cache path
- `/etc/npmrc`: NPM cache path

These config files work in non-login shells (cron, systemd, etc.).

#### Environment Variables (Override Purpose)
Users can override cache paths with environment variables:
- `CONDA_PKGS_DIRS`: Conda package cache
- `PIP_CACHE_DIR`: Pip cache
- `UV_CACHE_DIR`: uv cache

**Security Improvement**: Previous `PYTHONUSERBASE` sharing was removed due to security vulnerabilities.

### ⚡ uv Package Manager

`uv` is an ultra-fast Python package manager written in Rust (10-100x faster than pip).

#### Installation
```bash
sudo /data/scripts/install-uv.sh
```

#### Usage
```bash
# Use uv instead of pip
uv pip install numpy pandas torch

# Works in virtual environments
conda activate myenv
uv pip install package-name
```

#### Shared Cache
uv cache is stored at `/data/cache/uv` and shared among all users.

### 🔒 ACL-Based Permission Model

For security, we use **ACL (Access Control Lists)** instead of `chmod 777`.

#### Apply Permissions
```bash
sudo /data/scripts/system-permissions.sh
```

This script performs:
- Apply ACL to shared cache directories (`setfacl -d -m g:gpu-users:rwx`)
- Set setgid bit (`chmod 2775`) for group inheritance
- Safely migrate from `chmod 777`

#### Check Permissions
```bash
getfacl /data/cache/pip
```

### 🛠️ Sudoers for Non-Admin Users

Non-admin users can perform specific admin tasks (without password).

#### Allowed Commands
```bash
# Clean cache
sudo /data/scripts/ops-clean-cache.sh --all

# Check disk usage
sudo df -h /data
```

#### Setup
```bash
sudo /data/scripts/system-sudoers.sh
```

This creates `/etc/sudoers.d/aica-datakeeper` file to grant permissions safely.

### 🔄 Auto-Recovery Service

A systemd service that automatically restores environment after server reboot.

#### Register User
```bash
# Add new user to auto-recovery targets
sudo /data/scripts/user-register.sh username gpu-users
```

Registered users are stored in `/data/config/users.txt`.

#### Manual Recovery
```bash
# Full recovery (global env + all registered users)
sudo /data/scripts/ops-recovery.sh

# Dry-run (show plan without execution)
sudo /data/scripts/ops-recovery.sh --dry-run
```

#### Check Recovery Log
```bash
tail -f /var/log/aica-recovery.log
```

**Note**: systemd service can only be configured on actual servers (manual execution only on macOS dev environment).

### 📊 Disk Usage Alerts

Generates alerts when disk usage exceeds threshold.

#### Manual Execution
```bash
# Default threshold 80%
sudo /data/scripts/ops-disk-alert.sh

# Custom threshold
sudo /data/scripts/ops-disk-alert.sh --threshold 90

# Dry-run (don't write to log)
sudo /data/scripts/ops-disk-alert.sh --threshold 80 --dry-run
```

#### Cron Automation (Optional)
Check disk usage every hour:
```bash
echo '0 * * * * /data/scripts/ops-disk-alert.sh --threshold 80' | sudo crontab -
```

#### Check Log
```bash
cat /var/log/aica-disk-alert.log
```

### 🧙 Interactive Admin Wizard

Menu-based TUI integrating all setup tasks.

#### Run
```bash
sudo /data/scripts/admin-wizard.sh
```

#### Menu Items
1. Install Global Environment
2. Add New User
3. Setup Permissions
4. Configure Auto-Recovery
5. Test Configuration
6. Setup Cache Config
7. Setup uv
8. Exit

#### List Options (For Testing)
```bash
/data/scripts/admin-wizard.sh --list-options
```

**Note**: Automatically falls back to text menu if dialog/whiptail not available.

## 📚 Scenario-Based Guides

### 🔄 Restoring the Environment After Server Restart

After a server reboot, the SSD is reset, so you need to reconfigure the basic environment:

```bash
# 1. Switch to the root account
sudo -i

# 2. Restore global environment (Miniconda installation + environment variables)
/data/scripts/ops-setup-global.sh

# 3. Log out and log back in to apply environment variables
exit
```

This process performs the following tasks:
- Installs shared Miniconda if it doesn't exist
- Sets system environment variables (`/etc/profile.d/global_envs.sh`)
- Sets cache directory permissions

### 👤 Adding a New User

Here's the complete process for adding a new user:

```bash
# 1. Create a Linux user
sudo adduser username

# 2. Add to group (if needed)
sudo usermod -aG homiai username

# 3. Set up user environment (home directory linking, Conda setup, permissions)
sudo /data/scripts/user-setup.sh username

# 4. Test: Log in as that user
su - username
# or connect via SSH
```

This process performs the following tasks:
- Creates `/data/users/username` directory
- Links home directory to `/data/users/username`
- Sets up user Conda environment (.condarc, initialization, etc.)
- Sets correct file permissions

### 🔧 Restoring an Existing User Environment

When restoring a user after server restart or when a user environment has issues (broken symbolic links, permission problems, etc.):

```bash
# 1. Restore entire user environment (all settings at once)
sudo /data/scripts/user-setup.sh username

# Or perform individual tasks:

# 2a. Only restore home directory link
sudo /data/scripts/user-create-home.sh username

# 2b. Only restore Conda environment
sudo /data/scripts/user-setup-conda.sh username

# 2c. Only fix file permissions
sudo /data/scripts/user-fix-permissions.sh username
```

> **Note**: `user-setup.sh` can be safely used not only for setting up new users but also for restoring existing user environments. Existing data is preserved.

### 🧹 System Maintenance Tasks

Commands for regular maintenance tasks:

```bash
# Clean cache (free up disk space)
sudo /data/scripts/ops-clean-cache.sh --all

# Clean specific caches
sudo /data/scripts/ops-clean-cache.sh --conda  # Conda cache
sudo /data/scripts/ops-clean-cache.sh --pip    # Pip package cache
sudo /data/scripts/ops-clean-cache.sh --torch  # PyTorch model cache
sudo /data/scripts/ops-clean-cache.sh --hf     # HuggingFace cache
```

## 🚶 User Guide

### 🏁 Getting Started

When you log in to the server, your home directory is automatically a symbolic link pointing to `/data/users/username`. This means **all files are automatically saved to persistent storage**.

```bash
# Check home directory
ls -la ~
# Result: lrwxrwxrwx 1 username groupname xx xx xx xx /home/username -> /data/users/username
```

### 🐍 Using Conda Environments

The system has a shared Miniconda installation, which you can use as follows:

```bash
# Create a new environment
conda create -n myenv python=3.10

# Activate environment
conda activate myenv

# List environments
conda env list
```

User environments are automatically saved to `/data/users/username/.conda/envs`.

### 💾 Shared Cache Files

Packages and models are stored in a central cache and shared:

- Conda packages: `/data/cache/conda/pkgs`
- Pip packages: `/data/cache/pip`
- PyTorch models: `/data/models/torch`
- HuggingFace models: `/data/models/huggingface`

## 🔧 Troubleshooting

### ❓ Common Issues

| Issue | Solution |
|------|----------|
| 🔗 Broken home directory symbolic link | `sudo /data/scripts/user-create-home.sh <username>` |
| 🐍 Conda environment issues | `sudo /data/scripts/user-setup-conda.sh <username>` |
| 🔒 File permission issues | `sudo /data/scripts/user-fix-permissions.sh <username>` |
| 🌐 Environment variables not loading | `source /etc/profile.d/global_envs.sh` |

### 🔒 Permission Issues

If you encounter shared directory permission issues:

```bash
# Modify cache directory permissions
sudo chmod 777 /data/cache/conda/pkgs
sudo chmod 777 /data/cache/pip
```

## ⚠️ Precautions

- 🚫 **Do not store data on SSD**: All important files must be stored in the `/data/` path. The default disk (/) is reset on restart.
- 🔍 **Respect shared resources**: Shared caches and model directories are accessible to all users, so do not store sensitive information.
- ⚙️ **User environment modifications**: Modify personal environment settings in `.bashrc`, `.zshrc`, etc. files in your home directory.

## 📝 Technical Details

This project consists of the following scripts:

1. `install-miniconda.sh`: Global Miniconda installation
2. `install-global-env.sh`: System global environment variable settings (cache paths, etc.)
3. `user-create-home.sh`: Creating user data directory and home links
4. `user-setup-conda.sh`: User-specific Conda environment setup
5. `user-fix-permissions.sh`: User data directory permission management
6. `user-setup.sh`: Integrates the above scripts for batch user environment setup
7. `ops-setup-global.sh`: Global environment recovery after system reboot
8. `ops-clean-cache.sh`: Cache cleanup and disk space recovery

These scripts are located in the `/data/scripts/` path and can be run individually as needed.

## ⚠️ System Risks and Mitigation Strategies

While efficient, this setup has several potential risks:

### 1. Single Point of Failure Issue 🚨

- **Risk**: Hardware failure in the `/data` volume could result in loss of all user data.
- **Mitigation**: 
  - Regularly back up important data to the `/backup` volume.
  - Use commands like `rsync -av /data/users/ /backup/users/` for user data backup.

### 2. Permission and Security Vulnerabilities 🔓

- **Risk**: Shared cache/model directories are accessible to multiple users, creating risk of malicious code or package installation.
- **Mitigation**:
  - Only install packages from trusted sources.
  - Regularly check user permissions: `sudo /data/scripts/user-fix-permissions.sh <username>`

### 3. Resource Contention Issues ⚡

- **Risk**: Multiple users using the same physical disk simultaneously can cause I/O bottlenecks.
- **Mitigation**:
  - Perform large file operations outside peak hours.
  - Use the `ionice` command to adjust I/O priorities.

### 4. Shared Data Corruption Risk 🗑️

- **Risk**: Users with permissions could accidentally delete important shared directories, affecting all users.
- **Mitigation**:
  - Always verify paths before executing important commands.
  - Restrict permissions on shared directories so only administrators can modify them.

### 5. System Upgrade Difficulties 🔄

- **Risk**: Upgrading shared systems (Miniconda, etc.) can affect all user environments.
- **Mitigation**:
  - Notify all users before upgrading.
  - Validate upgrades in a test environment first.

### 💡 Recommendations for Safe Operation

- Perform regular backups (at least weekly)
- Educate all users on shared resource usage
- Utilize disk usage and performance monitoring tools
- Regularly clean caches to free up disk space

## 📞 Additional Information

For more details, please contact Eungbean Lee (eungbean@homilabs.ai).

## 🤝 Contributing

This project is open source and welcomes all contributions and suggestions:

- 🐛 Bug reports
- 💡 New feature suggestions
- 📝 Documentation improvements
- 🔧 Code improvements and refactoring

All contributions help improve the quality and stability of the project.
If you have any questions or suggestions, please feel free to contact us. 