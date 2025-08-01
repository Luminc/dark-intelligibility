# obsidian-sync.ps1
$vaultPath = "C:\Users\jeroe\Documents\Dark Intelligibility\"
cd $vaultPath

# Fetch and rebase if upstream has changes
git fetch origin
if (-not (git diff --quiet origin/main)) {
    Write-Host "Remote changes detected. Pulling..."
    git pull --rebase --autostash
}

# Add and commit local changes if any
if (-not (git diff --quiet)) {
    Write-Host "Local changes detected. Committing and pushing..."
    git add .
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    git commit -m "Auto-sync from PC at $timestamp"
    git push
} else {
    Write-Host "No local changes. Vault is up to date."
}
