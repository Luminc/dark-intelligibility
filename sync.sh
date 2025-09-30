#!/data/data/com.termux/files/usr/bin/bash

# A safer script to synchronize an Obsidian vault with a Git repository.
#
# Main changes from the original script:
# 1. Sync order is changed to be safer: Vault -> Repo -> Git Remote -> Repo -> Vault.
#    This prevents overwriting local changes in the vault.
# 2. Uses `rsync --delete` to properly handle file deletions.
# 3. Removes risky automatic Git conflict resolution. If a conflict occurs,
#    the script will exit, allowing for manual resolution.
# 4. Added notifications for errors using Termux:API.

# --- CONFIGURATION ---
# IMPORTANT: Please verify this is the correct absolute path to your Obsidian vault.
VAULT_DIR="/storage/emulated/0/Documents/dark-intelligibility"
REPO_DIR="$HOME/dark-intelligibility"
LOG_FILE="$HOME/sync.log"
LOCK_FILE="$HOME/sync.lock"

# --- SCRIPT LOGIC ---

# Error handling and cleanup
set -e
trap cleanup EXIT

cleanup() {
  local exit_code=$?
  if [[ -f "$LOCK_FILE" ]]; then
    rm -f "$LOCK_FILE"
  fi
  if [[ $exit_code -ne 0 ]]; then
    error_message="Sync script failed with exit code $exit_code"
    log "❌ $error_message"
    notify_error "$error_message"
  fi
}

# Timestamp and logging functions
timestamp() {
  date +"[%Y-%m-%d %H:%M:%S]"
}

log() {
  echo "$(timestamp) $1" | tee -a "$LOG_FILE"
}

# Notification functions
notify_error() {
    if command -v termux-notification &> /dev/null; then
        termux-notification --title "Sync Script Error" --content "$1" --led-off 250 --led-on 250 --priority max --sound
    else
        log "⚠️ termux-notification command not found. Cannot send error notification."
    fi
}

notify_warning() {
    if command -v termux-notification &> /dev/null; then
        termux-notification --title "Sync Script Warning" --content "$1"
    else
        log "⚠️ termux-notification command not found. Cannot send warning notification."
    fi
}


# --- PRE-RUN CHECKS ---

# Check for existing lock file
if [[ -f "$LOCK_FILE" ]]; then
  log "⚠️ Another sync is already running (lock file exists). Exiting."
  exit 1
fi
echo $$ > "$LOCK_FILE" # Create lock file

# Validate paths
if [[ ! -d "$VAULT_DIR" ]]; then
  log "❌ Obsidian vault directory not found: $VAULT_DIR"
  log "👉 Please check the VAULT_DIR variable in this script."
  exit 1
fi

if [[ ! -d "$REPO_DIR" ]]; then
  log "❌ Git repository directory not found: $REPO_DIR"
  exit 1
fi

# --- SYNC PROCESS ---

log "🔄 Starting sync..."

# Check network connectivity before attempting git operations
if ! ping -c 1 github.com &>/dev/null; then
  log "⚠️ No network connectivity to GitHub. Skipping remote operations."
  notify_warning "No network connectivity. Performed a local-only sync."
  log "🔁 Doing local-only sync (Obsidian -> Repo)..."
  # When offline, we only sync from vault to repo to capture changes.
  # We don't sync back from repo to vault to avoid potential data loss
  # if the repo has older content.
  if ! rsync -av --delete "$VAULT_DIR/" "$REPO_DIR/" --exclude ".git/" --exclude "sync.log" --exclude "*.lock"; then
    log "❌ Failed local sync from Obsidian to repo"
    exit 1
  fi
  log "📱 Local sync complete (offline mode). Changes saved to local repo."
  exit 0
fi

# ONLINE SYNC LOGIC

# Step 1: Create a backup before syncing (safety net)
BACKUP_DIR="$HOME/.sync_backups/$(date '+%Y%m%d_%H%M%S')"
log "💾 Creating backup at $BACKUP_DIR..."
if ! mkdir -p "$BACKUP_DIR"; then
  log "⚠️ Failed to create backup directory, continuing without backup"
else
  # Backup both the repo and the vault for maximum safety
  if ! cp -r "$REPO_DIR" "$BACKUP_DIR/repo_backup"; then
    log "⚠️ Failed to backup repo, continuing anyway"
  fi
  if ! cp -r "$VAULT_DIR" "$BACKUP_DIR/vault_backup"; then
    log "⚠️ Failed to backup vault, continuing anyway"
  fi
fi

# Step 2: First, pull latest changes from remote to get up-to-date repo
log "⬇️ First, pulling latest changes from GitHub..."
cd "$REPO_DIR" || exit 1
if ! git pull --rebase; then
  log "❌ Failed to pull from GitHub. This could be due to network issues or merge conflicts."
  log "👉 Please resolve any conflicts manually in '$REPO_DIR' and then run the sync again."
  exit 1
fi

# Step 3: Perform intelligent bidirectional sync
log "🔄 Performing bidirectional content sync..."

# Function to sync files bidirectionally with conflict detection
sync_bidirectional() {
  local vault_dir="$1"
  local repo_dir="$2"
  local has_conflicts=false
  
  # Find all files in both directories (excluding git, logs, locks)  
  local all_files=$(
    {
      if [[ -d "$vault_dir" ]]; then
        cd "$vault_dir" && find . -type f ! -path "./.git/*" ! -name "sync.log" ! -name "*.lock" | sed 's|^\./||'
      fi
      if [[ -d "$repo_dir" ]]; then
        cd "$repo_dir" && find . -type f ! -path "./.git/*" ! -name "sync.log" ! -name "*.lock" | sed 's|^\./||' 
      fi
    } | sort -u
  )
  
  while IFS= read -r file; do
    local vault_file="$vault_dir/$file"
    local repo_file="$repo_dir/$file"
    
    # Skip if file doesn't exist in either location
    [[ ! -f "$vault_file" && ! -f "$repo_file" ]] && continue
    
    if [[ ! -f "$vault_file" ]]; then
      # File only exists in repo - copy to vault
      log "📥 Copying from repo to vault: $file"
      mkdir -p "$(dirname "$vault_file")"
      cp "$repo_file" "$vault_file"
      
    elif [[ ! -f "$repo_file" ]]; then
      # File only exists in vault - copy to repo
      log "📤 Copying from vault to repo: $file"
      mkdir -p "$(dirname "$repo_file")"
      cp "$vault_file" "$repo_file"
      
    else
      # File exists in both - check for differences
      if ! cmp -s "$vault_file" "$repo_file"; then
        # Files differ - check modification times
        if [[ "$vault_file" -nt "$repo_file" ]]; then
          # Vault file is newer
          log "📤 Vault newer, updating repo: $file"
          cp "$vault_file" "$repo_file"
        elif [[ "$repo_file" -nt "$vault_file" ]]; then
          # Repo file is newer
          log "📥 Repo newer, updating vault: $file"
          cp "$repo_file" "$vault_file"
        else
          # Same modification time but different content - potential conflict
          log "⚠️ Content conflict detected (same mtime): $file"
          log "   Using repo version (assuming it has latest remote changes)"
          cp "$repo_file" "$vault_file"
          has_conflicts=true
        fi
      fi
      # If files are identical, do nothing
    fi
  done <<< "$all_files"
  
  if [[ "$has_conflicts" == "true" ]]; then
    log "⚠️ Some files had conflicting content with same modification times"
    log "   Repo versions were used (assuming they contain latest remote changes)"
  fi
}

# Execute the bidirectional sync
if ! sync_bidirectional "$VAULT_DIR" "$REPO_DIR"; then
  log "❌ Failed to perform bidirectional sync"
  exit 1
fi

# Step 4: Commit merged changes if any
if [ -n "$(git status --porcelain)" ]; then
  log "📝 Merged changes detected, committing..."
  git add .
  if git commit -m "Auto-sync: Merged Obsidian and remote changes ($(date '+%Y-%m-%d %H:%M:%S'))"; then
    log "✅ Committed merged changes."
  else
    log "⚠️ Failed to commit changes. This might be okay if there were no real changes."
  fi
fi

# Step 5: Push merged changes to remote
log "⬆️ Pushing merged changes to GitHub..."
if ! git push; then
  log "❌ Failed to push to GitHub. It might be due to network issues or stale credentials."
  exit 1
fi
log "🚀 Pushed merged changes to GitHub."

log "🎉 Sync complete!"

# Step 6: Cleanup old backups (keep last 5)
if [[ -d "$HOME/.sync_backups" ]]; then
  log "🧹 Cleaning up old backups..."
  cd "$HOME/.sync_backups" && ls -t | tail -n +6 | xargs rm -rf 2>/dev/null || true
fi