#!/usr/bin/env bash
set -euo pipefail

# Build PomodoCat as a proper .app bundle.
# Usage: ./build-app.sh [release|debug]   (default: release)

CONFIG="${1:-release}"
APP_NAME="PomodoCat"
BUNDLE_ID="com.pomellacat.pomodocat"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"

echo "▶ Building ($CONFIG)…"
cd "$ROOT_DIR"

# Wipe the SwiftPM-generated resource bundle so removed files don't linger
# (SwiftPM's incremental build doesn't prune them on its own).
STALE_BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path 2>/dev/null || true)"
if [[ -n "$STALE_BIN_DIR" && -d "$STALE_BIN_DIR/${APP_NAME}_${APP_NAME}.bundle" ]]; then
  rm -rf "$STALE_BIN_DIR/${APP_NAME}_${APP_NAME}.bundle"
fi

swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)/$APP_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "✖ Binary not found at $BIN_PATH" >&2
  exit 1
fi

echo "▶ Assembling .app bundle…"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"

# Copy SwiftPM-generated resource bundle (contains Resources/*) next to the binary,
# which is where Bundle.module looks for it at runtime.
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
RES_BUNDLE="$BIN_DIR/${APP_NAME}_${APP_NAME}.bundle"
if [[ -d "$RES_BUNDLE" ]]; then
  cp -R "$RES_BUNDLE" "$APP_DIR/Contents/MacOS/"
  echo "  ↳ Copied resource bundle: $(basename "$RES_BUNDLE")"
fi

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>                 <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>          <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>           <string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key>              <string>1</string>
  <key>CFBundleShortVersionString</key>   <string>0.1.0</string>
  <key>CFBundleExecutable</key>           <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>          <string>APPL</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>LSMinimumSystemVersion</key>       <string>13.0</string>
  <key>NSHighResolutionCapable</key>      <true/>
  <key>NSPrincipalClass</key>             <string>NSApplication</string>
  <key>LSApplicationCategoryType</key>    <string>public.app-category.productivity</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so Gatekeeper lets the bundle launch on the local machine.
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

echo "✔ Built: $APP_DIR"
echo ""
echo "Run with:"
echo "  open '$APP_DIR'"
