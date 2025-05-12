# 🚀 AICADataKeeper: NHN CLOUD AI Environment Manager

[![KR](https://img.shields.io/badge/lang-한국어-red.svg)](README.md)
[![EN](https://img.shields.io/badge/lang-English-blue.svg)](README_eng.md)

> Author: Eungbean Lee  
> Email: eungbean@homilabs.ai  
> Organization: HOMI AI

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
chmod +x /data/system/scripts/*.sh
```

## 📚 Scenario-Based Guides

### 🔄 Restoring the Environment After Server Restart

After a server reboot, the SSD is reset, so you need to reconfigure the basic environment:

```bash
# 1. Switch to the root account
sudo -i

# 2. Restore global environment (Miniconda installation + environment variables)
/data/system/scripts/setup_global_after_startup.sh

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
sudo /data/system/scripts/setup_new_user.sh username

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
sudo /data/system/scripts/setup_new_user.sh username

# Or perform individual tasks:

# 2a. Only restore home directory link
sudo /data/system/scripts/3_create_user_data_dir.sh username

# 2b. Only restore Conda environment
sudo /data/system/scripts/4_setup_user_conda.sh username

# 2c. Only fix file permissions
sudo /data/system/scripts/5_fix_user_permission.sh username
```

> **Note**: `setup_new_user.sh` can be safely used not only for setting up new users but also for restoring existing user environments. Existing data is preserved.

### 🧹 System Maintenance Tasks

Commands for regular maintenance tasks:

```bash
# Clean cache (free up disk space)
sudo /data/system/scripts/clean_cache.sh --all

# Clean specific caches
sudo /data/system/scripts/clean_cache.sh --conda  # Conda cache
sudo /data/system/scripts/clean_cache.sh --pip    # Pip package cache
sudo /data/system/scripts/clean_cache.sh --torch  # PyTorch model cache
sudo /data/system/scripts/clean_cache.sh --hf     # HuggingFace cache
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
| 🔗 Broken home directory symbolic link | `sudo /data/system/scripts/3_create_user_data_dir.sh <username>` |
| 🐍 Conda environment issues | `sudo /data/system/scripts/4_setup_user_conda.sh <username>` |
| 🔒 File permission issues | `sudo /data/system/scripts/5_fix_user_permission.sh <username>` |
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

1. `1_install_miniconda3_global.sh`: Global Miniconda installation
2. `2_install_global_env.sh`: System global environment variable settings (cache paths, etc.)
3. `3_create_user_data_dir.sh`: Creating user data directory and home links
4. `4_setup_user_conda.sh`: User-specific Conda environment setup
5. `5_fix_user_permission.sh`: User data directory permission management
6. `setup_new_user.sh`: Integrates the above scripts for batch user environment setup
7. `setup_global_after_startup.sh`: Global environment recovery after system reboot
8. `clean_cache.sh`: Cache cleanup and disk space recovery

These scripts are located in the `/data/system/scripts/` path and can be run individually as needed.

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
  - Regularly check user permissions: `sudo /data/system/scripts/5_fix_user_permission.sh <username>`

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