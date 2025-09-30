#!/data/data/com.termux/files/usr/bin/bash

# This script watches for file changes in the Obsidian vault and triggers the
# main sync script (`sync.sh`).
#
# Main changes from the original script:
# 1. The VAULT_DIR path has been corrected to match the one in `sync.sh`.
#    This is the most critical fix to ensure the watcher monitors the correct directory.
# 2. Added checks to ensure `inotifywait` is installed and the vault path is valid.
# 3. Improved logging to provide better feedback on what the watcher is doing.

# --- CONFIGURATION ---
# IMPORTANT: This path MUST match the VAULT_DIR in sync.sh
VAULT_DIR="/storage/emulated/0/Documents/dark-intelligibility"
SYNC_SCRIPT="$HOME/sync.sh"
DEBOUNCE_SECONDS=30 # Time to wait for more changes before syncing
COOLDOWN_SECONDS=600 # Minimum time between syncs (10 minutes)

# --- SCRIPT LOGIC ---

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Track last sync time for cooldown
last_sync_time=0

# Check if inotify-tools is installed
if ! command -v inotifywait &> /dev/null;
then
    log "❌ Error: inotifywait command not found."
    log "👉 Please install it by running: pkg install inotify-tools"
    exit 1
fi

# Check if vault directory exists
if [[ ! -d "$VAULT_DIR" ]]
then
  log "❌ Watcher error: Obsidian vault directory not found at $VAULT_DIR"
  log "👉 Please check the VAULT_DIR variable in both watchsync.sh and sync.sh"
  exit 1
fi

log "✅ Watcher started on: $VAULT_DIR"
log "🕒 Debounce time is $DEBOUNCE_SECONDS seconds, cooldown is $COOLDOWN_SECONDS seconds."

# Holds the process ID (PID) of the debounced sync job.
# This allows us to reset the timer if a new file change comes in.
sync_pid=0

# This function runs the sync script after a delay.
# If another change is detected during the delay, the previous timer is cancelled
# and a new one is started.
debounce_sync() {
  # Check cooldown period
  current_time=$(date +%s)
  time_since_last_sync=$((current_time - last_sync_time))
  
  if [[ $time_since_last_sync -lt $COOLDOWN_SECONDS ]]; then
    remaining_cooldown=$((COOLDOWN_SECONDS - time_since_last_sync))
    log "🕒 Sync on cooldown. ${remaining_cooldown}s remaining until next sync allowed."
    return
  fi

  # If a sync is already scheduled, cancel it.
  if [[ $sync_pid -ne 0 ]]
  then
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
    # Update last sync time
    last_sync_time=$(date +%s)
  ) & 
sync_pid=$!
}

# --- INITIAL SYNC ---
# Run sync once on startup to ensure everything is up-to-date.
log "🚀 Performing initial sync on startup..."
"$SYNC_SCRIPT"
last_sync_time=$(date +%s)

# --- WATCHER LOOP ---
# Monitor the vault for file creation, deletion, modification, and moves.
# The loop will pipe the events to the debounce function.
inotifywait -m -r \
  -e modify,create,delete,move \
  --format '%w%f' \
  "$VAULT_DIR"
| while read -r changed_file; do
  # Only log first change in a batch to reduce noise
  if [[ $sync_pid -eq 0 ]]; then
    log "👀 Detected changes, scheduling sync..."
  fi
  debounce_sync
done