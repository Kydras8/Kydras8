#!/bin/bash

echo "[+] Resetting Git configuration for Kydras8 profile repo..."

cd ~/Documents/Kydras8 || { echo "❌ Folder not found, exiting."; exit 1; }

echo "[+] Removing old .git tracking..."
rm -rf .git

echo "[+] Reinitializing fresh Git repo..."
git init
git branch -M main
git remote add origin https://github.com/Kydras8/Kydras8.git

echo "[+] Staging all files (including README.md)..."
git add README.md

echo "[+] Committing clean README.md..."
git commit -m "Clean reset: Branded profile README"

echo "[+] Pushing clean state to GitHub..."
git push --force --set-upstream origin main

echo "[✅] Done! Your GitHub profile repo is reset and clean!"
