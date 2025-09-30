#!/bin/bash

# macOS version of the Obsidian vault watcher script
# Adapted from watchsync.sh for Termux/Android
#
# Main changes:
# 1. Uses fswatch instead of inotifywait (macOS native file watcher)
# 2. Paths adjusted for macOS
# 3. Compatible with macOS bash

# --- CONFIGURATION ---
VAULT_DIR="$HOME/Documents/dark-intelligibility"
SYNC_SCRIPT="$VAULT_DIR/sync-macos.sh"
DEBOUNCE_SECONDS=15 # Time to wait for more changes before syncing
LOG_FILE="$VAULT_DIR/watchsync.log"

# --- SCRIPT LOGIC ---

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if fswatch is installed
if ! command -v fswatch &> /dev/null; then
    log "❌ Error: fswatch command not found."
    log "👉 Please install it by running: brew install fswatch"
    exit 1
fi

# Check if vault directory exists
if [[ ! -d "$VAULT_DIR" ]]; then
  log "❌ Watcher error: Obsidian vault directory not found at $VAULT_DIR"
  log "👉 Please check the VAULT_DIR variable in this script"
  exit 1
fi

# Check if sync script exists
if [[ ! -f "$SYNC_SCRIPT" ]]; then
  log "❌ Watcher error: Sync script not found at $SYNC_SCRIPT"
  exit 1
fi

log "✅ Watcher started on: $VAULT_DIR"
log "🕒 Debounce time is $DEBOUNCE_SECONDS seconds."

# Holds the process ID (PID) of the debounced sync job.
# This allows us to reset the timer if a new file change comes in.
sync_pid=0

# This function runs the sync script after a delay.
# If another change is detected during the delay, the previous timer is cancelled
# and a new one is started.
debounce_sync() {
  # If a sync is already scheduled, cancel it.
  if [[ $sync_pid -ne 0 ]]; then
    kill $sync_pid 2>/dev/null || true
  fi

  # Schedule the sync script to run after the debounce period.
  (
    sleep $DEBOUNCE_SECONDS
    log "⏳ Changes settled. Running sync script..."
    # Execute the sync script and log its output.
    if ! "$SYNC_SCRIPT"; then
      log "⚠️ Sync script finished with an error."
    else
      log "✅ Sync script finished successfully."
    fi
  ) &
  sync_pid=$!
}

# --- INITIAL SYNC ---
# Run sync once on startup to ensure everything is up-to-date.
log "🚀 Performing initial sync on startup..."
"$SYNC_SCRIPT"

# --- WATCHER LOOP ---
# Monitor the vault for file changes using fswatch.
# The -r flag enables recursive monitoring.
# The -e flag excludes patterns (we exclude .git, logs, and lock files).
log "👀 Watching for changes..."
fswatch -r \
  --exclude="\.git/" \
  --exclude="\.sync\.lock$" \
  --exclude="sync\.log$" \
  --exclude="watchsync\.log$" \
  --exclude="\.DS_Store$" \
  "$VAULT_DIR" \
| while read -r changed_file; do
  log "👀 Detected change: $changed_file"
  debounce_sync
done
