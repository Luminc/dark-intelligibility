#!/data/data/com.termux/files/usr/bin/bash

echo "🔁 Syncing from Obsidian to local repo..."

rsync -av --delete ~/storage/shared/Obsidian/dark-intelligibility/ ~/dark-intelligibility/

cd ~/dark-intelligibility || exit

git add .
if git diff-index --quiet HEAD; then
  echo "✅ No changes to commit"
else
  git commit -m "🔄 Sync from Obsidian: $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo "🚀 Pushing to GitHub..."
git push
