#!/bin/bash

echo "🛡️  Starte Backup & GitHub Push..."

# Datum & Uhrzeit für Commit
DATUM=$(date "+%Y-%m-%d %H:%M")

# Änderungen hinzufügen
echo "�� Füge Änderungen hinzu..."
git add .

# Commit erstellen
git commit -m "💾 Backup: Build stabil am $DATUM"

# GitHub Remote hinzufügen (nur beim ersten Mal nötig)
echo "🌐 GitHub Remote wird gesetzt auf dein Repository..."
git remote remove origin 2> /dev/null
git remote add origin https://github.com/SandroGansner/LMS_App_V1.0_Backup.git

# Push auf GitHub
echo "🚀 Pushe auf GitHub..."
git push -u origin main

echo "✅ Fertig! Alles sicher auf GitHub gepusht 🎉"

