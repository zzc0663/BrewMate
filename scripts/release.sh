#!/bin/bash
set -euo pipefail

APP_NAME="${APP_NAME:-BrewMate}"
VERSION_FILE="${VERSION_FILE:-VERSION}"
APP_VERSION="$(tr -d '[:space:]' < "${VERSION_FILE}")"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
APP_BUNDLE="${APP_NAME}.app"
RELEASE_DIR="${RELEASE_DIR:-dist}"
RELEASE_BASENAME="${APP_NAME}-v${APP_VERSION}"
ZIP_PATH="${RELEASE_DIR}/${RELEASE_BASENAME}.zip"

mkdir -p "${RELEASE_DIR}"

echo "==> Building release ${APP_VERSION} (${BUILD_NUMBER})..."
BUILD_NUMBER="${BUILD_NUMBER}" bash build.sh

if [ "${SIGN_AND_NOTARIZE:-0}" = "1" ]; then
    echo "==> Signing and notarizing release..."
    BUILD_NUMBER="${BUILD_NUMBER}" \
    APP_BUNDLE="${APP_BUNDLE}" \
    ZIP_PATH="${ZIP_PATH}" \
    bash scripts/notarize_app.sh
else
    echo "==> Creating release zip..."
    rm -f "${ZIP_PATH}"
    ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"
fi

echo "==> Rendering release notes..."
OUTPUT_PATH="${RELEASE_DIR}/release-notes-v${APP_VERSION}.md" \
bash scripts/render_release_notes.sh >/dev/null

echo "==> Release ready"
echo "    Version: ${APP_VERSION}"
echo "    App: ${APP_BUNDLE}"
echo "    Zip: ${ZIP_PATH}"
echo "    Notes: ${RELEASE_DIR}/release-notes-v${APP_VERSION}.md"
