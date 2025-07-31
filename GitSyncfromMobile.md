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

### 1. `sync-from-obsidian.sh`

```
#!/data/data/com.termux/files/usr/bin/bash

cd "$HOME/storage/shared/Obsidian/dark-intelligibility"
echo "[$(date '+%F %T')] 🔄 Starting sync..."

# Pull latest
echo "[$(date '+%F %T')] ⬇️ Pulling latest changes..."
git pull --rebase

# Sync Obsidian vault to local git repo
echo "[$(date '+%F %T')] 🔁 Syncing files from Obsidian to local repo..."
rsync -av --delete --exclude ".git" ./ .gitrepo/

# Commit changes
cd .gitrepo
git add .
git diff --cached --quiet || {
  git commit -m "🔄 Sync from Obsidian: $(date '+%F %T')"
  git push
  echo "[$(date '+%F %T')] 🚀 Pushed changes to GitHub."
}

# Sync back
cd ..
rsync -av --delete .gitrepo/ ./
echo "[$(date '+%F %T')] ✅ Sync complete."
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

```
chmod +x sync-from-obsidian.sh watchsync.sh
```

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
|Merge conflicts|Pull regularly and avoid conflicting edits|

---

## 🧪 Future Upgrades

- Use `cron` or `at` jobs on Termux (via `cronie`)
    
- Auto-start `watchsync.sh` on boot via `termux-services`
    
- Sync encrypted vaults (e.g. with Obsidian Encryption Plugin)
    

---

Happy syncing! 🌀

Feel free to improve this guide and commit your changes back.