#!/bin/bash
# [08] 사용자 홈 마이그레이션 스크립트
# 역할: 기존 아키텍처에서 새 하이브리드 아키텍처로 마이그레이션

set -e

USERNAME=$1
GROUPNAME=${2:-gpu-users}
DRY_RUN=false
ROLLBACK=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --rollback) ROLLBACK=true ;;
  esac
done

# Validate input
if [ -z "$USERNAME" ]; then
    echo "[ERROR] Username required."
    echo "[ERROR] Usage: $0 <username> [groupname] [--dry-run|--rollback]"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script requires root privileges."
    echo "[ERROR] Usage: sudo $0 $@"
    exit 1
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo "[ERROR] User '$USERNAME' does not exist."
    exit 1
fi

USER_HOME="/home/$USERNAME"
USER_DATA="/data/users/$USERNAME"
USER_DOTFILES="$USER_DATA/dotfiles"
BACKUP_MARKER="$USER_DATA/.migration-backup-$(date +%Y%m%d%H%M%S)"

# Dotfiles to migrate
DOTFILES=(".bashrc" ".zshrc" ".profile" ".condarc" ".hpcrc" ".gitconfig" ".vimrc" ".tmux.conf")
DOTDIRS=(".ssh")

# Helper functions
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
}

log_warning() {
    echo "[WARNING] $1"
}

phase_backup() {
    log_info "Phase 1/3: Backup..."
    
    # Check current state
    local home_type="directory"
    local home_target=""
    
    if [ -L "$USER_HOME" ]; then
        home_type="symlink"
        home_target=$(readlink "$USER_HOME")
    elif [ -d "$USER_HOME" ]; then
        home_type="directory"
    else
        home_type="not_found"
    fi
    
    log_info "Current home type: $home_type"
    if [ -n "$home_target" ]; then
        log_info "Current home target: $home_target"
    fi
    
    # Create backup marker with metadata
    local backup_dir="$BACKUP_MARKER"
    
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$backup_dir"
        
        # Create backup metadata
        cat > "$backup_dir/metadata.txt" << EOF
migration_timestamp=$(date +%Y%m%d%H%M%S)
username=$USERNAME
groupname=$GROUPNAME
home_type=$home_type
home_target=$home_target
script_version=1.0.0
EOF
        
        # Backup dotfiles that exist
        for dotfile in "${DOTFILES[@]}"; do
            if [ -e "$USER_DATA/$dotfile" ]; then
                cp -a "$USER_DATA/$dotfile" "$backup_dir/" 2>/dev/null || true
                echo "backed_up_dotfile=$dotfile" >> "$backup_dir/metadata.txt"
            fi
        done
        
        for dotdir in "${DOTDIRS[@]}"; do
            if [ -e "$USER_DATA/$dotdir" ]; then
                cp -a "$USER_DATA/$dotdir" "$backup_dir/" 2>/dev/null || true
                echo "backed_up_dotdir=$dotdir" >> "$backup_dir/metadata.txt"
            fi
        done
        
        log_info "Backup created at: $backup_dir"
    else
        log_info "[DRY-RUN] Would create backup at: $backup_dir"
    fi
}

phase_convert() {
    log_info "Phase 2/3: Convert..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would convert $USERNAME to new architecture"
        log_info "[DRY-RUN] 1. Move dotfiles to $USER_DOTFILES/"
        log_info "[DRY-RUN] 2. Remove old home symlink if exists"
        log_info "[DRY-RUN] 3. Call user-create-home-v2.sh"
        log_info "[DRY-RUN] 4. Call user-setup-dotfiles.sh"
        return
    fi
    
    # 1. Move dotfiles to dotfiles/ subdirectory
    log_info "Moving dotfiles to dotfiles/ subdirectory..."
    mkdir -p "$USER_DOTFILES"
    
    for dotfile in "${DOTFILES[@]}"; do
        if [ -e "$USER_DATA/$dotfile" ] && [ ! -L "$USER_DATA/$dotfile" ]; then
            mv "$USER_DATA/$dotfile" "$USER_DOTFILES/"
            log_info "Moved $dotfile to dotfiles/"
        fi
    done
    
    for dotdir in "${DOTDIRS[@]}"; do
        if [ -e "$USER_DATA/$dotdir" ] && [ ! -L "$USER_DATA/$dotdir" ]; then
            mv "$USER_DATA/$dotdir" "$USER_DOTFILES/"
            log_info "Moved $dotdir to dotfiles/"
        fi
    done
    
    # 2. Remove old symlink if it exists
    if [ -L "$USER_HOME" ]; then
        log_info "Removing old home symlink..."
        rm "$USER_HOME"
    fi
    
    # 3. Call user-create-home-v2.sh
    log_info "Creating new home architecture..."
    if [ -x "$SCRIPT_DIR/user-create-home-v2.sh" ]; then
        "$SCRIPT_DIR/user-create-home-v2.sh" "$USERNAME" "$GROUPNAME"
    else
        log_error "user-create-home-v2.sh not found or not executable"
        exit 1
    fi
    
    # 4. Call user-setup-dotfiles.sh
    log_info "Setting up dotfile symlinks..."
    if [ -x "$SCRIPT_DIR/user-setup-dotfiles.sh" ]; then
        "$SCRIPT_DIR/user-setup-dotfiles.sh" "$USERNAME" "$GROUPNAME"
    else
        log_error "user-setup-dotfiles.sh not found or not executable"
        exit 1
    fi
}

phase_verify() {
    log_info "Phase 3/3: Verify..."
    
    local verification_failed=false
    
    # Check 1: /home/<user> is directory (not symlink)
    if [ -L "$USER_HOME" ]; then
        log_error "Home is still a symlink: $USER_HOME"
        verification_failed=true
    elif [ -d "$USER_HOME" ]; then
        log_info "✓ Home is a directory: $USER_HOME"
    else
        log_error "Home directory not found: $USER_HOME"
        verification_failed=true
    fi
    
    # Check 2: ~/data symlink exists and points correctly
    local data_link="$USER_HOME/data"
    if [ -L "$data_link" ]; then
        local data_target=$(readlink "$data_link")
        if [ "$data_target" = "$USER_DATA" ]; then
            log_info "✓ Data symlink correct: $data_link -> $data_target"
        else
            log_error "Data symlink points to wrong location: $data_link -> $data_target (expected: $USER_DATA)"
            verification_failed=true
        fi
    else
        log_error "Data symlink not found: $data_link"
        verification_failed=true
    fi
    
    # Check 3: dotfile symlinks exist
    local missing_dotfiles=()
    for dotfile in "${DOTFILES[@]}"; do
        local dotfile_link="$USER_HOME/$dotfile"
        if [ -e "$USER_DOTFILES/$dotfile" ]; then
            if [ -L "$dotfile_link" ]; then
                local dotfile_target=$(readlink "$dotfile_link")
                if [ "$dotfile_target" = "data/dotfiles/$dotfile" ]; then
                    log_info "✓ Dotfile symlink correct: $dotfile"
                else
                    log_error "Dotfile symlink incorrect: $dotfile -> $dotfile_target (expected: data/dotfiles/$dotfile)"
                    verification_failed=true
                fi
            else
                log_error "Dotfile symlink missing: $dotfile_link"
                verification_failed=true
            fi
        fi
    done
    
    # Check 4: Test login
    log_info "Testing user login..."
    if sudo -u "$USERNAME" bash -c "echo 'Login test successful'" &>/dev/null; then
        log_info "✓ User login test successful"
    else
        log_error "User login test failed"
        verification_failed=true
    fi
    
    if [ "$verification_failed" = true ]; then
        log_error "Verification failed! Migration may be incomplete."
        exit 1
    fi
    
    log_info "✓ All verification checks passed"
}

do_rollback() {
    log_info "Rollback: Restoring previous state..."
    
    # Find latest backup marker
    local latest_backup=$(find "$USER_DATA" -name ".migration-backup-*" -type d | sort | tail -1)
    
    if [ -z "$latest_backup" ]; then
        log_error "No backup found for rollback"
        exit 1
    fi
    
    log_info "Using backup: $latest_backup"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would restore from backup: $latest_backup"
        return
    fi
    
    # Read backup metadata
    local metadata_file="$latest_backup/metadata.txt"
    if [ ! -f "$metadata_file" ]; then
        log_error "Backup metadata not found"
        exit 1
    fi
    
    local home_type=$(grep "^home_type=" "$metadata_file" | cut -d= -f2)
    local home_target=$(grep "^home_target=" "$metadata_file" | cut -d= -f2)
    
    # Restore dotfiles from backup
    log_info "Restoring dotfiles from backup..."
    
    # Move existing dotfiles back to user data if they exist
    for dotfile in "${DOTFILES[@]}"; do
        if [ -e "$USER_DOTFILES/$dotfile" ]; then
            mv "$USER_DOTFILES/$dotfile" "$USER_DATA/"
        fi
    done
    
    for dotdir in "${DOTDIRS[@]}"; do
        if [ -e "$USER_DOTFILES/$dotdir" ]; then
            mv "$USER_DOTFILES/$dotdir" "$USER_DATA/"
        fi
    done
    
    # Restore from backup if backups exist
    for dotfile in "${DOTFILES[@]}"; do
        if [ -e "$latest_backup/$dotfile" ]; then
            cp -a "$latest_backup/$dotfile" "$USER_DATA/"
            log_info "Restored $dotfile from backup"
        fi
    done
    
    for dotdir in "${DOTDIRS[@]}"; do
        if [ -e "$latest_backup/$dotdir" ]; then
            cp -a "$latest_backup/$dotdir" "$USER_DATA/"
            log_info "Restored $dotdir from backup"
        fi
    done
    
    # Remove new home structure
    log_info "Removing new home structure..."
    rm -rf "$USER_HOME"
    
    # Restore original home structure
    if [ "$home_type" = "symlink" ] && [ -n "$home_target" ]; then
        log_info "Restoring original home symlink: $USER_HOME -> $home_target"
        ln -s "$home_target" "$USER_HOME"
    else
        log_info "Original home was not a symlink, leaving as directory"
    fi
    
    # Remove dotfiles subdirectory if empty
    if [ -d "$USER_DOTFILES" ] && [ -z "$(ls -A "$USER_DOTFILES" 2>/dev/null)" ]; then
        rmdir "$USER_DOTFILES"
        log_info "Removed empty dotfiles directory"
    fi
    
    # Clean up backup marker
    rm -rf "$latest_backup"
    log_info "Rollback completed successfully"
}

# Main logic
if [ "$ROLLBACK" = true ]; then
    do_rollback
    exit 0
fi

if [ "$DRY_RUN" = true ]; then
    log_info "Dry run: Would migrate $USERNAME"
    log_info "  - Current home: $(ls -ld "$USER_HOME" 2>/dev/null || echo 'not found')"
    log_info "  - User data: $USER_DATA"
    log_info "  - Phases: backup → convert → verify"
    exit 0
fi

# Check if user is already using new architecture
if [ ! -L "$USER_HOME" ] && [ -L "$USER_HOME/data" ] && [ "$(readlink "$USER_HOME/data")" = "$USER_DATA" ]; then
    log_warning "User '$USERNAME' appears to already be using new architecture"
    log_warning "Proceeding may cause data loss. Use --rollback if needed."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Migration cancelled"
        exit 0
    fi
fi

phase_backup
phase_convert
phase_verify

log_info "Success: Migration complete for $USERNAME"
log_info "Backup available at: $BACKUP_MARKER"
log_info "To rollback: $0 $USERNAME --rollback"