#!/bin/bash

# Automatisches Backup-Skript für LMS_Finanzen_v1.0
echo "📦 Starte automatisches GitHub-Backup..."

cd "$(dirname "$0")"

# Stage alle Änderungen
git add .

# Commit mit aktuellem Datum
git commit -m "🕒 Auto-Backup: 2025-03-24 20:48" || echo "⚠️  Nichts zu committen."

# Push zum Remote-Repository
git push origin main

echo "✅ Auto-Backup abgeschlossen."
