#!/bin/bash
# build_app.sh – Builds FlightTracker and creates a proper .app bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="MyFlightTracker"
BINARY_NAME="FlightTracker"   # from Package.swift — cannot change without rebuilding
ICON_NAME="MyFlightTracker"
BUILD_DIR="$SCRIPT_DIR/.build/release"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"

# Icon paths
ICON_SRC="$SCRIPT_DIR/$ICON_NAME.png"
ICON_SET="$SCRIPT_DIR/$ICON_NAME.iconset"
ICNS_FILE="$SCRIPT_DIR/$ICON_NAME.icns"

# DMG output
DMG_DIR="$HOME/Documents/Pi/$APP_NAME"
DMG_FILE="$DMG_DIR/$APP_NAME.dmg"

mkdir -p "$DMG_DIR"

echo "🔨 Building $APP_NAME (release)..."
cd "$SCRIPT_DIR"
swift build -c release

echo "📦 Creating .app bundle..."

# Create bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary (SPM produces FlightTracker, not MyFlightTracker)
cp "$BUILD_DIR/$BINARY_NAME" "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$BINARY_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.yvonneivory.myflighttracker</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.3.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.3.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>$ICON_NAME</string>
    <key>CFBundleIconName</key>
    <string>$ICON_NAME</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSUserNotificationsUsageDescription</key>
    <string>$APP_NAME mengirim notifikasi saat harga tiket mencapai titik terendah baru.</string>
    <key>LSUIElement</key>
    <false/>
    <key>LSBackgroundOnly</key>
    <false/>
</dict>
</plist>
EOF

# Copy icon
if [ -f "$ICNS_FILE" ]; then
    cp "$ICNS_FILE" "$APP_BUNDLE/Contents/Resources/$ICON_NAME.icns"
    echo "  ✅ Icon copied: $ICNS_FILE"
elif [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$APP_BUNDLE/Contents/Resources/$ICON_NAME.png"
    echo "  ✅ Icon (PNG) copied: $ICON_SRC"
fi

echo "✅ Built: $APP_BUNDLE"

# ── Code sign (ad-hoc) ──
echo ""
echo "🔒 Signing app bundle..."
codesign --force --deep --sign - \
  --entitlements "$SCRIPT_DIR/MyFlightTracker.entitlements" \
  --identifier "com.yvonneivory.myflighttracker" \
  "$APP_BUNDLE" 2>&1 && echo "  ✅ Signed" || echo "  ⚠️  Sign failed (app still runs)"

# ── Build DMG ──
echo ""
echo "📦 Building DMG..."

# Staging area
DMG_STAGE="/tmp/${APP_NAME}_dmg_stage"
rm -rf "$DMG_STAGE"
mkdir -p "$DMG_STAGE"

# Copy app into staging
cp -r "$APP_BUNDLE" "$DMG_STAGE/"

# Symlink to /Applications for drag-install
ln -s /Applications "$DMG_STAGE/Applications"

# Also copy scraper.py so it's bundled alongside the app
if [ -f "$SCRIPT_DIR/scraper.py" ]; then
  mkdir -p "$DMG_STAGE/Resources"
  cp "$SCRIPT_DIR/scraper.py" "$DMG_STAGE/Resources/scraper.py"
fi

# Create a README in the DMG
cat > "$DMG_STAGE/Cara Instalasi.txt" << 'READMEEOF'
Cara Instalasi MyFlightTracker
================================
1. Drag "MyFlightTracker.app" ke folder "Applications"
2. Pertama kali buka: klik kanan pada app → "Open" → "Open" lagi
   (karena app ini tidak di-sign dengan Apple Developer ID)
3. Salin "Resources/scraper.py" ke folder Applications:
   cp /Volumes/MyFlightTracker/Resources/scraper.py ~/Applications/
   atau ke: ~/FlightTracker/scraper.py

Kebutuhan Sistem:
- macOS 14 (Sonoma) atau lebih baru
- Python/uv untuk scraping harga real: ~/.local/bin/uv
  Install dengan: curl -LsSf https://astral.sh/uv/install.sh | sh

Demo Mode tersedia tanpa internet — aktifkan di Pengaturan.
READMEEOF

# Remove quarantine from staging area
xattr -rc "$DMG_STAGE" 2>/dev/null || true

# Calculate size needed
APP_SIZE=$(du -sm "$DMG_STAGE" | awk '{print $1}')
DMG_SIZE=$(( APP_SIZE + 20 ))  # +20MB padding

# Build DMG using hdiutil
TMP_DMG="/tmp/${APP_NAME}_tmp.dmg"
FINAL_DMG="$DMG_FILE"

rm -f "$TMP_DMG" "$FINAL_DMG"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGE" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  -size ${DMG_SIZE}m \
  "$FINAL_DMG" 2>&1

if [ -f "$FINAL_DMG" ]; then
  DMG_SIZE_MB=$(du -sh "$FINAL_DMG" | awk '{print $1}')
  echo ""
  echo "✅ DMG selesai!"
  echo "   📍 Lokasi : $FINAL_DMG"
  echo "   📦 Ukuran : $DMG_SIZE_MB"
  echo ""
  echo "Bagikan file ini ke teman-temanmu."
  echo "Cara buka di macOS: double-click → drag app ke Applications."
  # Reveal in Finder
  open "$DMG_DIR"
else
  echo "❌ DMG gagal dibuat"
  exit 1
fi

# Cleanup staging
rm -rf "$DMG_STAGE"
