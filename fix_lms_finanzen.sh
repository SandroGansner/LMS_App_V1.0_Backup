#!/bin/bash

# Pfad zum Projektverzeichnis
PROJECT_DIR="/Users/sandrogansner/Projects/LMS_Finanzen_v1.0"
IOS_DIR="$PROJECT_DIR/ios"
MACOS_DIR="$PROJECT_DIR/macos"

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Funktion zum Prüfen, ob ein Befehl erfolgreich war
check_status() {
  if [ $? -ne 0 ]; then
    echo -e "${RED}Fehler bei $1. Abbruch...${NC}"
    exit 1
  fi
}

echo "Starte Reparaturprozess für LMS_Finanzen_v1.0..."

# 1. Bearbeite die xcconfig-Dateien für iOS
echo "Bearbeite iOS xcconfig-Dateien..."
for config in Release Debug Profile; do
  CONFIG_FILE="$IOS_DIR/Flutter/$config.xcconfig"
  if [ -f "$CONFIG_FILE" ]; then
    # Prüfe, ob die Zeile bereits existiert
    if ! grep -q "#include \"Target Support Files/Pods-Runner/Pods-Runner.$config_lowercase.xcconfig\"" "$CONFIG_FILE"; then
      echo "#include \"Target Support Files/Pods-Runner/Pods-Runner.$config_lowercase.xcconfig\"" >> "$CONFIG_FILE"
      echo "Füge #include zu $CONFIG_FILE hinzu."
    else
      echo "$CONFIG_FILE wurde bereits korrekt bearbeitet."
    fi
  else
    echo -e "${RED}Fehler: $CONFIG_FILE existiert nicht!${NC}"
    exit 1
  fi
done

# 2. Bearbeite das macOS-Podfile (Deployment-Target auf 10.15 setzen)
echo "Bearbeite macOS-Podfile..."
PODFILE="$MACOS_DIR/Podfile"
if [ -f "$PODFILE" ]; then
  # Ersetze platform :osx, '10.14' durch platform :osx, '10.15'
  sed -i '' 's/platform :osx, '\''10.14'\''/platform :osx, '\''10.15'\''/' "$PODFILE"
  check_status "Ersetzen von platform im macOS-Podfile"

  # Ersetze MACOSX_DEPLOYMENT_TARGET = '10.14' durch MACOSX_DEPLOYMENT_TARGET = '10.15'
  sed -i '' 's/MACOSX_DEPLOYMENT_TARGET'\'' = '\''10.14/MACOSX_DEPLOYMENT_TARGET'\'' = '\''10.15/' "$PODFILE"
  check_status "Ersetzen von MACOSX_DEPLOYMENT_TARGET im macOS-Podfile"
else
  echo -e "${RED}Fehler: $PODFILE existiert nicht!${NC}"
  exit 1
fi

# 3. Bearbeite pubspec.yaml (Entferne cloud_firestore, füge http hinzu)
echo "Bearbeite pubspec.yaml..."
PUBSPEC="$PROJECT_DIR/pubspec.yaml"
if [ -f "$PUBSPEC" ]; then
  # Entferne cloud_firestore
  sed -i '' '/cloud_firestore:/d' "$PUBSPEC"
  check_status "Entfernen von cloud_firestore aus pubspec.yaml"

  # Füge http hinzu, falls nicht vorhanden
  if ! grep -q "http:" "$PUBSPEC"; then
    sed -i '' '/dependencies:/a\
    http: ^1.2.0' "$PUBSPEC"
    check_status "Hinzufügen von http zu pubspec.yaml"
  fi
else
  echo -e "${RED}Fehler: $PUBSPEC existiert nicht!${NC}"
  exit 1
fi

# 4. Bereinige Flutter-Projekt
echo "Bereinige Flutter-Projekt..."
cd "$PROJECT_DIR"
flutter clean
check_status "flutter clean"
flutter pub get
check_status "flutter pub get"

# 5. Bereinige und installiere Pods für iOS
echo "Bereinige und installiere Pods für iOS..."
cd "$IOS_DIR"
pod deintegrate
check_status "pod deintegrate (iOS)"
pod install --repo-update
check_status "pod install (iOS)"

# 6. Bereinige und installiere Pods für macOS
echo "Bereinige und installiere Pods für macOS..."
cd "$MACOS_DIR"
pod deintegrate
check_status "pod deintegrate (macOS)"
pod install --repo-update
check_status "pod install (macOS)"

# 7. Lösche DerivedData
echo "Lösche DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData
check_status "Löschen von DerivedData"

# 8. Hinweis zum Bauen
echo -e "${GREEN}Reparaturprozess abgeschlossen!${NC}"
echo "Du kannst das Projekt jetzt neu bauen:"
echo "- Für iOS: Öffne Xcode mit 'open $IOS_DIR/Runner.xcworkspace' und drücke Cmd + R."
echo "- Für macOS: Führe 'flutter run -d macos' im Verzeichnis $PROJECT_DIR aus."

