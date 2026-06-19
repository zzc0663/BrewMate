#!/bin/bash
set -euo pipefail

PROFILE_NAME="${1:-BrewMateNotary}"

echo "==> Storing notarization credentials in Keychain profile: ${PROFILE_NAME}"
echo "    You can use either Apple ID + app-specific password"
echo "    or App Store Connect API key credentials."

xcrun notarytool store-credentials "${PROFILE_NAME}"

echo "==> Done!"
echo "    Use this profile later with:"
echo "    NOTARY_PROFILE=${PROFILE_NAME} bash scripts/notarize_app.sh"
