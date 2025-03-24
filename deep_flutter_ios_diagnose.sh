#!/bin/bash

echo "🧠 Starte tiefgreifende Flutter iOS Diagnose & Reparatur..."

LOGFILE="diagnose.log"
echo "" > "$LOGFILE"

log() {
  echo "$1" | tee -a "$LOGFILE"
}

# 1. Doppelte Ordnerstruktur checken
log "📂 Überprüfe doppelte ios-Ordner..."
if [ -d "ios/ios" ]; then
  log "❌ ios/ios-Ordner gefunden – wird gelöscht."
  rm -rf ios/ios
else
  log "✅ Kein doppelter ios/ios-Ordner."
fi

# 2. Flutter Standard-Dateien checken
log "📄 Überprüfe Flutter iOS Standarddateien..."

REQUIRED_FILES=("Runner.xcworkspace" "Runner.xcodeproj" "AppFrameworkInfo.plist")
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -e "ios/Flutter/$file" ] && [[ "$file" == *plist ]]; then
    log "🛠 Erstelle fehlende $file..."
    mkdir -p ios/Flutter
    cat <<EOF > ios/Flutter/AppFrameworkInfo.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
EOF
  elif [ ! -e "ios/$file" ]; then
    log "⚠️ $file fehlt! Bitte mit flutter create neu erzeugen!"
  else
    log "✅ $file ist vorhanden."
  fi
done

# 3. Alte Build-Caches löschen
log "🧹 Entferne alte Xcode- und Flutter-Caches..."
flutter clean
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Generated.xcconfig
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/ephemeral
rm -rf build/

# 4. Flutter pub & pod install
log "📦 Installiere Flutter Dependencies..."
flutter pub get

log "📲 Installiere CocoaPods..."
cd ios || exit
pod install --repo-update || pod install
cd ..

# 5. Diagnose: flutter doctor
log "🩺 Starte flutter doctor..."
flutter doctor -v | tee -a "$LOGFILE"

# 6. Diagnose: Build-Test
log "🧪 Teste iOS Build..."
flutter build ios >> "$LOGFILE" 2>&1
BUILD_STATUS=$?

if [ "$BUILD_STATUS" -ne 0 ]; then
  log "❌ Build fehlgeschlagen! Sieh dir diagnose.log für Details an!"
else
  log "✅ Build erfolgreich abgeschlossen!"
fi

