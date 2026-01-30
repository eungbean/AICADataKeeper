# Home Architecture Migration Guide

## Pre-requisites Complete ✅

All migration scripts have been created and verified:

| Script | Purpose |
|--------|---------|
| `verify-global-env.sh` | Verify environment variables |
| `user-create-home-v2.sh` | Create hybrid home structure |
| `user-setup-dotfiles.sh` | Setup dotfile symlinks |
| `install-recovery-check.sh` | Race condition prevention |
| `migrate-user-home.sh` | 3-phase migration with rollback |
| `ops-recovery.sh` | Updated recovery for both architectures |

## Migration Steps (Requires Sudo)

### Step 1: Fix Git Permissions (One-time)
```bash
sudo chmod -R g+w /data/AICADataKeeper/.git/objects/
```

### Step 2: Canary Migration (Test with one user)
```bash
cd /data/AICADataKeeper

# Dry-run first
sudo ./scripts/migrate-user-home.sh testuser_qa --dry-run

# Execute migration
sudo ./scripts/migrate-user-home.sh testuser_qa homi

# Verify
test -d /home/testuser_qa && echo "✓ Real directory (not symlink)"
test -L /home/testuser_qa/data && echo "✓ ~/data symlink exists"
test -L /home/testuser_qa/.bashrc && echo "✓ Dotfile symlinks exist"
sudo -u testuser_qa bash -c "echo 'Login test: OK'"

# Test rollback (optional but recommended)
sudo ./scripts/migrate-user-home.sh testuser_qa --rollback
# Then re-migrate:
sudo ./scripts/migrate-user-home.sh testuser_qa homi
```

### Step 3: Full Migration (After canary success)
```bash
# Migrate registered users
sudo ./scripts/migrate-user-home.sh space homi
sudo ./scripts/migrate-user-home.sh ys homi

# Install recovery check script
sudo ./scripts/install-recovery-check.sh

# Verify environment
./scripts/verify-global-env.sh
```

### Step 4: Commit Changes
```bash
git add scripts/*.sh MIGRATION_GUIDE.md
git commit -m "feat(scripts): add hybrid home architecture migration system

- Add user-create-home-v2.sh for new hybrid architecture
- Add user-setup-dotfiles.sh for persistent dotfile symlinks
- Add migrate-user-home.sh with 3-phase migration and rollback
- Add install-recovery-check.sh for race condition prevention
- Add verify-global-env.sh for environment validation
- Update ops-recovery.sh to support both v1 and v2 architectures"
```

## Architecture Overview

```
OLD (v1):
/home/<user> → /data/users/<user>  (full NFS symlink)

NEW (v2):
/home/<user>/                      (SSD - real directory)
├── .cache/pip, .cache/uv, etc.    (SSD - fast I/O)
├── .bashrc → ~/data/dotfiles/.bashrc
├── .ssh/   → ~/data/dotfiles/.ssh/
└── data/   → /data/users/<user>/  (NFS symlink)
    ├── dotfiles/                  (persistent)
    ├── conda/envs/                (persistent)
    └── projects/                  (persistent)
```

## Rollback

If issues occur after migration:
```bash
sudo ./scripts/migrate-user-home.sh <username> --rollback
```

## Verification Commands

```bash
# Check architecture
test -d /home/<user> && ! test -L /home/<user> && echo "v2 architecture"
test -L /home/<user> && echo "v1 architecture"

# Check dotfiles
ls -la /home/<user>/.bashrc  # Should be symlink

# Check data link
readlink /home/<user>/data  # Should point to /data/users/<user>

# Verify environment
./scripts/verify-global-env.sh
```
