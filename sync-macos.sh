#!/bin/bash

# macOS version of the Obsidian vault sync script
# Adapted from sync.sh for Termux/Android
#
# Main changes:
# 1. Paths adjusted for macOS
# 2. Termux notifications replaced with osascript (native macOS notifications)
# 3. Compatible with macOS bash and filesystem

# --- CONFIGURATION ---
VAULT_DIR="$HOME/Documents/dark-intelligibility"
REPO_DIR="$HOME/Documents/dark-intelligibility"  # Same as vault on macOS
LOG_FILE="$VAULT_DIR/sync.log"
LOCK_FILE="$VAULT_DIR/.sync.lock"

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
    osascript -e "display notification \"$1\" with title \"Obsidian Sync Error\" sound name \"Basso\""
}

notify_warning() {
    osascript -e "display notification \"$1\" with title \"Obsidian Sync Warning\""
}

notify_success() {
    osascript -e "display notification \"$1\" with title \"Obsidian Sync\" sound name \"Glass\""
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

if [[ ! -d "$REPO_DIR/.git" ]]; then
  log "❌ Git repository not found in: $REPO_DIR"
  exit 1
fi

# --- SYNC PROCESS ---

log "🔄 Starting sync..."

# Check network connectivity with retry
MAX_RETRIES=3
RETRY_DELAY=5
retry_count=0

log "🌐 Checking network connectivity..."
while [ $retry_count -lt $MAX_RETRIES ]; do
  if ping -c 1 -t 2 github.com &>/dev/null; then
    log "✅ Network connection established"
    break
  fi
  retry_count=$((retry_count + 1))
  if [ $retry_count -lt $MAX_RETRIES ]; then
    log "⏳ No network (attempt $retry_count/$MAX_RETRIES). Retrying in ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY
  fi
done

if [ $retry_count -eq $MAX_RETRIES ]; then
  log "⚠️ No network connectivity to GitHub after $MAX_RETRIES attempts. Skipping remote operations."
  notify_warning "No network connectivity. Sync skipped."
  exit 0
fi

# ONLINE SYNC LOGIC

# Step 1: Create a backup before syncing (safety net)
BACKUP_DIR="$HOME/.sync_backups/$(date '+%Y%m%d_%H%M%S')"
log "💾 Creating backup at $BACKUP_DIR..."
if ! mkdir -p "$BACKUP_DIR"; then
  log "⚠️ Failed to create backup directory, continuing without backup"
else
  # Backup the vault for maximum safety (excluding .git to save space)
  if ! rsync -a --exclude=".git" "$VAULT_DIR/" "$BACKUP_DIR/vault_backup/"; then
    log "⚠️ Failed to backup vault, continuing anyway"
  fi
fi

# Step 2: Pull latest changes from remote with autostash
log "⬇️ Pulling latest changes from GitHub..."
cd "$REPO_DIR" || exit 1

if ! git pull --rebase --autostash origin master; then
  log "❌ Failed to pull from GitHub. This could be due to network issues or merge conflicts."
  log "👉 Please resolve any conflicts manually in '$REPO_DIR' and then run the sync again."
  exit 1
fi

# Step 3: Add and commit any local changes
if [[ -n "$(git status --porcelain)" ]]; then
  log "📝 Local changes detected, committing..."
  git add .
  if git commit -m "Auto-sync from macOS: $(date '+%Y-%m-%d %H:%M:%S')"; then
    log "✅ Committed local changes."
  else
    log "⚠️ Failed to commit changes. This might be okay if there were no real changes."
  fi
fi

# Step 4: Push changes to remote
log "⬆️ Pushing changes to GitHub..."
if ! git push origin master; then
  log "❌ Failed to push to GitHub. It might be due to network issues or the remote being ahead."
  log "👉 Try running 'git pull --rebase' manually in '$REPO_DIR'"
  exit 1
fi
log "🚀 Pushed changes to GitHub."

log "🎉 Sync complete!"
notify_success "Obsidian vault synced successfully"

# Step 5: Cleanup old backups (keep last 5)
if [[ -d "$HOME/.sync_backups" ]]; then
  log "🧹 Cleaning up old backups..."
  cd "$HOME/.sync_backups" && ls -t | tail -n +6 | xargs rm -rf 2>/dev/null || true
fi
