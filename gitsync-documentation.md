
# Obsidian Vault Git Sync with Termux — Documentation
## Overview

This setup enables automatic syncing of your Obsidian vault between your Android device and GitHub, **without using cloud services or paid subscriptions**. It uses Termux with Git, `inotifywait` for real-time filesystem watching, and optional cron jobs for periodic syncs.

---

## Components

- **Vault directory:**  
    Your Obsidian vault folder on Android (e.g. `/storage/shared/Obsidian/dark-intelligibility`).
    
- **Git repository:**  
    A GitHub repo linked to your vault folder for version control and remote backup.
    
- **Scripts:**
    
    - `sync.sh` — runs a pull, then rsync to sync files, then push to GitHub.
        
    - `watchsync.sh` — monitors vault file changes and triggers `sync.sh` after 15 seconds of no new changes (debounce).
        
    - Optional cron jobs for scheduled sync.
        
- **Termux environment:**  
    Android terminal emulator with Linux tools installed (`git`, `inotify-tools`, `termux-api`).
    

---

## Setup

1. **Grant Termux storage access:**
    
    bash
    
    CopyEdit
    
    `termux-setup-storage`
    
2. **Clone your vault repo to local storage:**
    
    bash
    
    CopyEdit
    
    `cd ~/storage/shared/Obsidian git clone git@github.com:YourUsername/YourVaultRepo.git`
    
3. **Make scripts executable:**
    
    bash
    
    CopyEdit
    
    `chmod +x ~/sync.sh ~/watchsync.sh`
    
4. **Install necessary packages:**
    
    bash
    
    CopyEdit
    
    `pkg update pkg install git inotify-tools termux-api`
    
5. **Configure git safe directories:**
    
    bash
    
    CopyEdit
    
    `git config --global --add safe.directory /storage/emulated/0/Obsidian/YourVaultRepo`
    
6. **(Optional) Setup cron jobs:**
    
    Open crontab editor:
    
    bash
    
    CopyEdit
    
    `crontab -e`
    
    Add entries for periodic syncing (example: every hour):
    
    ruby
    
    CopyEdit
    
    `0 * * * * /data/data/com.termux/files/home/sync.sh`
    

---

## Usage

- **Manual sync:**  
    Run in Termux:
    
    bash
    
    CopyEdit
    
    `~/sync.sh`
    
- **Real-time automatic sync:**  
    Run watcher script in Termux:
    
    bash
    
    CopyEdit
    
    `~/watchsync.sh`
    
    Leave this session running to automatically sync after changes with debounce.
    
- **Cron sync:**  
    Runs automatically at scheduled intervals (if configured).
    
- **Termux widget:**  
    Create a shortcut to `sync.sh` for one-tap manual sync from your home screen.
    

---

## How It Works

- **`sync.sh`:**
    
    - Pulls latest from GitHub
        
    - Uses `rsync` to copy changed files between Obsidian vault and Termux repo folder
        
    - Commits and pushes local changes to GitHub
        
- **`watchsync.sh`:**
    
    - Uses `inotifywait` to watch for file changes recursively
        
    - When detected, waits 15 seconds to debounce multiple rapid changes
        
    - Runs `sync.sh` once changes stabilize
        
- **Cron:**
    
    - Fallback to scheduled syncs if watcher is not running
        

---

## Tips & Troubleshooting

- Make sure all scripts are executable (`chmod +x <script>`).
    
- Grant Termux storage access (`termux-setup-storage`) at first setup.
    
- Use SSH keys with GitHub for passwordless authentication.
    
- Adjust debounce time in `watchsync.sh` to balance battery use and sync responsiveness.
    
- Check logs (`sync.log`) for detailed sync output and errors.
    
- If permission errors appear, verify file permissions and safe.directory Git config.
    
- To stop watcher, simply Ctrl+C the Termux session running `watchsync.sh`.