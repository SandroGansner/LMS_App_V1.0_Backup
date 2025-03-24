#!/bin/bash

echo "🛡️  Starte Backup & GitHub Push..."

# Projektpfad
cd /Users/sandrogansner/Projects/LMS_Finanzen_v1.0 || { echo "❌ Projektordner nicht gefunden"; exit 1; }

# Git init, falls noch nicht vorhanden
if [ ! -d ".git" ]; then
    echo "🆕 Initialisiere neues Git-Repo..."
    git init
fi

# Alle Änderungen hinzufügen
echo "📦 Füge Änderungen hinzu..."
git add .

# Commit mit Timestamp
NOW=$(date +"%Y-%m-%d %H:%M")
git commit -m "💾 Backup: Build stabil am $NOW"

# Falls noch kein Remote gesetzt ist, bitte URL eintragen:
if ! git remote | grep origin >/dev/null; then
    echo "🌐 GitHub Remote wird hinzugefügt..."
    read -p "🔑 GitHub Repo-URL (z. B. https://github.com/deinname/LMS_Finanzen.git): " repo_url
    git remote add origin "$repo_url"
fi

# Auf Branch "main" pushen
git branch -M main
git push -u origin main

echo "✅ Fertig! Alles sicher auf GitHub gepusht 🎉"

