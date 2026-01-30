#!/bin/bash
set -e

USERNAME=$1
GROUPNAME=${2:-gpu-users}

USER_HOME="/home/$USERNAME"
USER_DATA="/data/users/$USERNAME"
USER_DOTFILES="$USER_DATA/dotfiles"
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config"

DOTFILES=(".bashrc" ".zshrc" ".profile" ".condarc" ".hpcrc" ".gitconfig" ".vimrc" ".tmux.conf")
DOTDIRS=(".ssh" ".oh-my-zsh")

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script requires root privileges."
    echo "[ERROR] Usage: sudo $0 <username> [groupname]"
    exit 1
fi

if [ -z "$USERNAME" ]; then
    echo "[ERROR] Username is required."
    echo "[ERROR] Usage: sudo $0 <username> [groupname]"
    exit 1
fi

if ! echo "$USERNAME" | grep -qE '^[a-z_][a-z0-9_-]*$'; then
    echo "[ERROR] Invalid username format: $USERNAME"
    echo "[ERROR] Username must contain only lowercase letters, numbers, underscores, and hyphens"
    echo "[ERROR] Must start with a letter or underscore"
    exit 1
fi

if ! id "$USERNAME" >/dev/null 2>&1; then
    echo "[ERROR] User '$USERNAME' does not exist."
    exit 1
fi

if [ ! -d "$USER_DATA" ]; then
    echo "[ERROR] User data directory not found: $USER_DATA"
    echo "[ERROR] Run user-create-home.sh first."
    exit 1
fi

if [ ! -d "$USER_DOTFILES" ]; then
    echo "[INFO] Creating dotfiles directory: $USER_DOTFILES"
    mkdir -p "$USER_DOTFILES"
    chown "$USERNAME:$GROUPNAME" "$USER_DOTFILES"
    chmod 755 "$USER_DOTFILES"
fi

setup_dotfile() {
    local dotfile="$1"
    local src="$USER_DOTFILES/$dotfile"
    local dst="$USER_HOME/$dotfile"
    
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "[INFO] Already linked: $dotfile"
        return 0
    fi
    
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "[INFO] Moving existing $dotfile to dotfiles directory"
        mv "$dst" "$src"
        chown "$USERNAME:$GROUPNAME" "$src"
        chmod 644 "$src"
    fi
    
    if [ ! -e "$src" ]; then
        if [ "$dotfile" = ".hpcrc" ] && [ -f "$CONFIG_DIR/.hpcrc" ]; then
            echo "[INFO] Creating default $dotfile from config"
            cp "$CONFIG_DIR/.hpcrc" "$src"
            chown "$USERNAME:$GROUPNAME" "$src"
            chmod 644 "$src"
        else
            echo "[INFO] Creating empty $dotfile"
            touch "$src"
            chown "$USERNAME:$GROUPNAME" "$src"
            chmod 644 "$src"
        fi
    fi
    
    echo "[INFO] Creating symlink: $dst -> $src"
    ln -sf "$src" "$dst"
    chown -h "$USERNAME:$GROUPNAME" "$dst"
}

setup_dotdir() {
    local dotdir="$1"
    local src="$USER_DOTFILES/$dotdir"
    local dst="$USER_HOME/$dotdir"
    
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "[INFO] Already linked: $dotdir"
        return 0
    fi
    
    if [ "$dotdir" = ".ssh" ]; then
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            echo "[INFO] Moving existing $dotdir to dotfiles directory"
            mv "$dst" "$src"
            chown -R "$USERNAME:$GROUPNAME" "$src"
            chmod 700 "$src"
        fi
        
        if [ ! -e "$src" ]; then
            echo "[INFO] Creating $dotdir directory"
            mkdir -p "$src"
            chown "$USERNAME:$GROUPNAME" "$src"
            chmod 700 "$src"
        fi
        
        echo "[INFO] Creating symlink: $dst -> $src"
        ln -sf "$src" "$dst"
        chown -h "$USERNAME:$GROUPNAME" "$dst"
    else
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            mv "$dst" "$src"
            chown -R "$USERNAME:$GROUPNAME" "$src"
            chmod 755 "$src"
        fi
        
        if [ ! -e "$src" ]; then
            mkdir -p "$src"
            chown "$USERNAME:$GROUPNAME" "$src"
            chmod 755 "$src"
        fi
        
        ln -sf "$src" "$dst"
        chown -h "$USERNAME:$GROUPNAME" "$dst"
    fi
}

echo "[INFO] Setting up dotfiles for user: $USERNAME"
echo "[INFO] Home directory: $USER_HOME"
echo "[INFO] Dotfiles directory: $USER_DOTFILES"

for dotfile in "${DOTFILES[@]}"; do
    setup_dotfile "$dotfile"
done

for dotdir in "${DOTDIRS[@]}"; do
    setup_dotdir "$dotdir"
done

echo "[INFO] Dotfile setup completed for user: $USERNAME"
echo "[INFO] All dotfiles are now symlinked to persistent storage"