#!/bin/bash
set -euo pipefail

APP_NAME="BrewMate"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
ASSETS_DIR="Assets"
APP_ICON_ICNS="${ASSETS_DIR}/AppIcon.icns"
VERSION_FILE="VERSION"
APP_VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

if [ ! -f "${APP_ICON_ICNS}" ]; then
    echo "==> Generating app icon..."
    node scripts/generate_app_icon.js
fi

echo "==> Building ${APP_NAME} (release)..."
swift build -c release

echo "==> Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

if [ -f "${APP_ICON_ICNS}" ]; then
    echo "==> Copying app icon..."
    cp "${APP_ICON_ICNS}" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>BrewMate</string>
    <key>CFBundleIdentifier</key>
    <string>com.zzc.BrewMate</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>BrewMate</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Done! ${APP_BUNDLE} created."
echo "    Run: open ${APP_BUNDLE}"
echo "    Sign/notarize: SIGN_IDENTITY='Developer ID Application: ...' bash scripts/notarize_app.sh"
