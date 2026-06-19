#!/bin/bash
set -euo pipefail

APP_NAME="${APP_NAME:-BrewMate}"
APP_BUNDLE="${APP_BUNDLE:-${APP_NAME}.app}"
VERSION_FILE="${VERSION_FILE:-VERSION}"
APP_VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
ZIP_PATH="${ZIP_PATH:-${APP_NAME}-v${APP_VERSION}.zip}"
NOTARY_PROFILE="${NOTARY_PROFILE:-BrewMateNotary}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-entitlements.plist}"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "error: app bundle not found: ${APP_BUNDLE}" >&2
    echo "hint: run 'bash build.sh' first" >&2
    exit 1
fi

if [ -z "${SIGN_IDENTITY}" ]; then
    echo "error: SIGN_IDENTITY is required" >&2
    echo "hint: export SIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)'" >&2
    exit 1
fi

if [ ! -f "${ENTITLEMENTS_PATH}" ]; then
    echo "error: entitlements file not found: ${ENTITLEMENTS_PATH}" >&2
    exit 1
fi

echo "==> Signing ${APP_BUNDLE}..."
codesign \
    --force \
    --deep \
    --options runtime \
    --entitlements "${ENTITLEMENTS_PATH}" \
    --sign "${SIGN_IDENTITY}" \
    "${APP_BUNDLE}"

echo "==> Verifying signature..."
codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"
spctl --assess --type exec --verbose=4 "${APP_BUNDLE}"

echo "==> Creating notarization archive..."
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

echo "==> Submitting for notarization..."
xcrun notarytool submit "${ZIP_PATH}" \
    --keychain-profile "${NOTARY_PROFILE}" \
    --wait

echo "==> Stapling notarization ticket..."
xcrun stapler staple -v "${APP_BUNDLE}"

echo "==> Validating stapled ticket..."
xcrun stapler validate -v "${APP_BUNDLE}"

echo "==> Done!"
echo "    Signed app: ${APP_BUNDLE}"
echo "    Notarized zip: ${ZIP_PATH}"
