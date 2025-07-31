# 📱 Termux + Obsidian Git Sync User Guide (2025 Edition)

A concise walkthrough to set up automatic Git sync for your Obsidian vault using Termux on Android, with support for watchers and clean cross-device syncing.

---

## 🔧 Prerequisites

### ✅ On Android

- Termux from F-Droid
    
- `pkg install git openssh rsync inotify-tools`
    
- `termux-setup-storage` and allow permissions
    
- GitHub repo set up and SSH key added (use `ssh-keygen` + `ssh-add`)
    

### ✅ On Desktop (optional but recommended)

- Git installed
    
- Text editor (VS Code, Obsidian)
    
- Repo cloned to local folder
    
- Optional: configure pull-on-launch behavior
    

---

## 📂 Folder Structure

```
/storage/shared/Obsidian/dark-intelligibility
├── .git/
├── sync-from-obsidian.sh
├── watchsync.sh
```

Your Obsidian vault should live in `/storage/shared/Obsidian/{vault-name}`.

---

## 🔄 Git Sync Scripts

### 1. `sync-from-obsidian.sh` (Enhanced Version)

```bash
#!/data/data/com.termux/files/usr/bin/bash

# Set up paths
VAULT_DIR="$HOME/storage/shared/Obsidian/dark-intelligibility"
REPO_DIR="$HOME/dark-intelligibility"
LOG_FILE="$HOME/sync.log"
LOCK_FILE="$HOME/sync.lock"

# Error handling
set -e
trap cleanup EXIT

cleanup() {
  local exit_code=$?
  if [[ -f "$LOCK_FILE" ]]; then
    rm -f "$LOCK_FILE"
  fi
  if [[ $exit_code -ne 0 ]]; then
    log "❌ Script failed with exit code $exit_code"
  fi
}

# Check for existing lock
if [[ -f "$LOCK_FILE" ]]; then
  log "⚠️ Another sync is already running (lock file exists). Exiting."
  exit 1
fi

# Create lock file
echo $$ > "$LOCK_FILE"

# Timestamp
timestamp() {
  date +"[%Y-%m-%d %H:%M:%S]"
}

log() {
  echo "$(timestamp) $1" | tee -a "$LOG_FILE"
}

# Validate paths exist
if [[ ! -d "$VAULT_DIR" ]]; then
  log "❌ Obsidian vault directory not found: $VAULT_DIR"
  exit 1
fi

if [[ ! -d "$REPO_DIR" ]]; then
  log "❌ Git repository directory not found: $REPO_DIR"
  exit 1
fi

log "🔄 Starting sync..."

# Check network connectivity
if ! ping -c 1 github.com &>/dev/null; then
  log "⚠️ No network connectivity to GitHub. Skipping remote operations."
  # Just do local sync without git operations
  log "🔁 Doing local-only sync..."
  if ! rsync -av "$VAULT_DIR/" "$REPO_DIR/" --exclude ".git/" --exclude "sync.log" --exclude "*.lock"; then
    log "❌ Failed local sync from Obsidian to repo"
    exit 1
  fi
  if ! rsync -av "$REPO_DIR/" "$VAULT_DIR/" --exclude ".git/" --exclude "sync.log" --exclude "*.lock"; then
    log "❌ Failed local sync from repo to Obsidian"
    exit 1
  fi
  log "📱 Local sync complete (offline mode)"
  exit 0
fi

# Step 1: Pull latest changes from GitHub
log "⬇️ Pulling latest changes..."
cd "$REPO_DIR" || exit 1

# Check if we have uncommitted changes before pulling
if [[ -n "$(git status --porcelain)" ]]; then
  log "⚠️ Uncommitted changes detected, stashing before pull..."
  git stash push -m "Auto-stash before sync $(date '+%Y-%m-%d %H:%M:%S')"
fi

if ! git pull --rebase --autostash; then
  log "❌ Failed to pull from GitHub. Attempting merge strategy..."
  if ! git pull --no-rebase; then
    log "❌ Both rebase and merge failed. Manual intervention required."
    # Check if there are merge conflicts
    if git status | grep -q "both modified"; then
      log "🔀 Merge conflicts detected. Attempting auto-resolution..."
      git status --porcelain | grep "^UU" | cut -c4- | while read -r file; do
        log "🔧 Auto-resolving conflict in: $file"
        git checkout --ours "$file"
        git add "$file"
      done
      if git commit --no-edit; then
        log "✅ Auto-resolved conflicts and committed"
      else
        log "❌ Failed to commit after conflict resolution"
        exit 1
      fi
    else
      exit 1
    fi
  fi
fi

# Step 2: Create backup before syncing (safety net)
BACKUP_DIR="$HOME/.sync_backups/$(date '+%Y%m%d_%H%M%S')"
log "💾 Creating backup at $BACKUP_DIR..."
if ! mkdir -p "$BACKUP_DIR"; then
  log "⚠️ Failed to create backup directory, continuing without backup"
else
  if ! cp -r "$REPO_DIR" "$BACKUP_DIR/repo_backup"; then
    log "⚠️ Failed to backup repo, continuing anyway"
  fi
fi

# Step 3: Sync from Obsidian vault to local repo
log "🔁 Syncing files from Obsidian to local repo..."
if ! rsync -av "$VAULT_DIR/" "$REPO_DIR/" --exclude ".git/" --exclude "sync.log" --exclude "*.lock"; then
  log "❌ Failed to sync from Obsidian to repo"
  exit 1
fi

# Step 4: Check for changes
cd "$REPO_DIR" || exit 1
if [ -n "$(git status --porcelain)" ]; then
  log "📝 Changes detected, committing..."
  if ! git add .; then
    log "❌ Failed to stage changes"
    exit 1
  fi
  if ! git commit -m "🔄 Sync from Obsidian: $(date '+%Y-%m-%d %H:%M:%S')"; then
    log "❌ Failed to commit changes"
    exit 1
  fi
  if ! git push; then
    log "❌ Failed to push to GitHub"
    exit 1
  fi
  log "🚀 Pushed changes to GitHub."
else
  log "✅ No changes to commit."
fi

# Step 5: Sync back from repo to vault (to catch any pulls)
log "🔁 Syncing files from local repo back to Obsidian vault..."
if ! rsync -av "$REPO_DIR/" "$VAULT_DIR/" --exclude ".git/" --exclude "sync.log" --exclude "*.lock"; then
  log "❌ Failed to sync from repo to Obsidian"
  exit 1
fi

log "🎉 Sync complete!"

# Cleanup old backups (keep last 5)
if [[ -d "$HOME/.sync_backups" ]]; then
  log "🧹 Cleaning up old backups..."
  cd "$HOME/.sync_backups" && ls -t | tail -n +6 | xargs rm -rf 2>/dev/null || true
fi
```

### 2. `watchsync.sh`

```
#!/data/data/com.termux/files/usr/bin/bash

VAULT_DIR="$HOME/storage/shared/Obsidian/dark-intelligibility"
SCRIPT="$VAULT_DIR/sync-from-obsidian.sh"

# Make sure the sync script is executable
chmod +x "$SCRIPT"

# Watch vault directory recursively
inotifywait -m -r -e modify,create,delete,move "$VAULT_DIR" --format '%w%f' \
| while read file; do
  echo "[watcher] Change detected: $file"
  sleep 15  # debounce
  "$SCRIPT"
done
```

Make both scripts executable:

```bash
chmod +x sync-from-obsidian.sh watchsync.sh
```

### 🎯 Enhanced Features

The updated sync script includes several robust features:

- **🔒 Lock File Protection**: Prevents multiple sync processes from running simultaneously
- **🌐 Network Connectivity Check**: Automatically detects offline mode and performs local-only sync
- **💾 Automatic Backups**: Creates timestamped backups before each sync (keeps last 5)
- **🔀 Conflict Resolution**: Attempts automatic resolution of merge conflicts
- **📝 Comprehensive Logging**: All operations logged with timestamps to `~/sync.log`
- **⚠️ Error Handling**: Robust error handling with proper cleanup on exit
- **🧹 Auto-cleanup**: Removes old backup directories automatically

---

## 🏃 Running the Watcher

In Termux:

```
cd ~/storage/shared/Obsidian/dark-intelligibility
./watchsync.sh
```

To run in the background or survive reboots, consider `tmux`, `termux-wake-lock`, or `termux-services`.

---

## 🧠 Git Discipline for Multi-device Sync

- **Always pull before editing on a new device**
    
- **Avoid concurrent edits to the same file** (especially same line/frontmatter)
    
- **Resolve conflicts manually or with tools like VS Code diff view**
    
- Submodules are fine but require conscious pushing from both main and submodule repos
    

### Optional Automation (Desktop)

- Pull on Obsidian launch via shell script or `.bat/.sh` launcher
    
- Pre-commit hooks for validation
    

---

## ✅ Troubleshooting

|Issue|Fix|
|---|---|
|`Permission denied`|`chmod +x` on script or `termux-setup-storage` again|
|No sync on edit|Confirm `watchsync.sh` is running, not killed|
|Merge conflicts|Script now auto-resolves conflicts, check `~/sync.log` for details|
|Sync already running|Another process has a lock, wait or remove `~/sync.lock` if stale|
|Network issues|Script automatically switches to offline mode for local sync|
|Backup failures|Check disk space, backups stored in `~/.sync_backups/`|
|Script errors|Check `~/sync.log` for detailed error messages and timestamps|

---

## 🧪 Current Automation Features

- **Cron Integration**: Schedule automatic syncs with `crontab -e`
  ```bash
  # Sync every 30 minutes
  */30 * * * * /data/data/com.termux/files/home/storage/shared/Obsidian/dark-intelligibility/sync-from-obsidian.sh
  ```
- **File Watcher**: Real-time sync on file changes using `inotifywait`
- **Service Integration**: Auto-start `watchsync.sh` on boot via `termux-services`

## 🔮 Future Upgrades

- Sync encrypted vaults (e.g. with Obsidian Encryption Plugin)
- Web dashboard for sync status monitoring
- Multi-vault support with configuration files
    

---

Happy syncing! 🌀

Feel free to improve this guide and commit your changes back.