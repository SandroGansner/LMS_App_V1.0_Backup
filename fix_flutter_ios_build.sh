#!/bin/bash

echo "📁 Erstelle AppFrameworkInfo.plist ..."
mkdir -p ios/Flutter
cat <<PLIST > ios/Flutter/AppFrameworkInfo.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.apple.flutter.framework</string>
</dict>
</plist>
PLIST

echo "🧹 Flutter clean ..."
flutter clean

echo "📦 Flutter pub get ..."
flutter pub get

echo "📡 Pod install ..."
cd ios
pod install
cd ..

echo "🛠️ Build iOS App ..."
flutter build ios

echo "✅ Fertig! 🎉 Wenn noch Fehler auftauchen, gib Bescheid!"
