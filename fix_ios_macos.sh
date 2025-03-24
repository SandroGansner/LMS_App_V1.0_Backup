#!/bin/bash

echo "🧹 Starte Hardcore-Wiederherstellung Flutter iOS & macOS..."

# Backup lib, assets, pubspec
echo "🔐 Sichere lib/ assets/ pubspec.yaml..."
cp -r lib lib_backup
cp -r assets assets_backup
cp pubspec.yaml pubspec_backup.yaml

# iOS & macOS Verzeichnisse löschen
echo "🧨 Entferne ios/ macos/"
rm -rf ios macos

# Neu generieren
echo "🛠 Erstelle ios/ macos neu..."
flutter create .

# Wiederherstellen
echo "♻️ Wiederherstellen von lib/ & assets/ & pubspec.yaml"
rm -rf lib assets
mv lib_backup lib
mv assets_backup assets
mv pubspec_backup.yaml pubspec.yaml

# Clean Build
flutter clean
flutter pub get

# iOS: Pod install
cd ios
pod install
cd ..

# Test
flutter doctor -v
flutter build ios
flutter build macos

