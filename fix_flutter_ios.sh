#!/bin/bash

echo "🧹 LMS Finanzen iOS-Projekt wird aufgeräumt..."

# 1. Check & entferne doppelte ios/ios-Ordner
if [ -d "ios/ios" ]; then
  echo "❌ ios/ios-Ordner gefunden – wird gelöscht..."
  rm -rf ios/ios
else
  echo "✅ Kein doppelter ios/ios-Ordner gefunden."
fi

# 2. AppFrameworkInfo.plist sicherstellen
if [ ! -f "ios/Flutter/AppFrameworkInfo.plist" ]; then
  echo "📄 AppFrameworkInfo.plist fehlt – wird erstellt..."
  mkdir -p ios/Flutter
  cat <<EOF > ios/Flutter/AppFrameworkInfo.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
EOF
else
  echo "✅ AppFrameworkInfo.plist ist vorhanden."
fi

# 3. Flutter clean & pub get
echo "🚿 flutter clean..."
flutter clean

echo "📦 flutter pub get..."
flutter pub get

# 4. Pod install
echo "📲 Wechsle in ios/ und installiere CocoaPods..."
cd ios || exit
pod install
cd ..

# 5. Build starten
echo "🏗 Starte iOS-Build..."
flutter build ios

echo "✅ Aufräumen & Build abgeschlossen!"

