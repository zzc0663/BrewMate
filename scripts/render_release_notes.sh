#!/bin/bash
set -euo pipefail

VERSION_FILE="${VERSION_FILE:-VERSION}"
TEMPLATE_PATH="${TEMPLATE_PATH:-.github/release-notes-template.md}"
OUTPUT_PATH="${OUTPUT_PATH:-dist/release-notes.md}"
CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.md}"
VERSION_VALUE="$(tr -d '[:space:]' < "${VERSION_FILE}")"

mkdir -p "$(dirname "${OUTPUT_PATH}")"

if [ -f "${CHANGELOG_PATH}" ]; then
    awk -v version="${VERSION_VALUE}" '
        $0 ~ "^## \\[" version "\\]" { in_section=1; next }
        in_section && $0 ~ "^## \\[" { exit }
        in_section { print }
    ' "${CHANGELOG_PATH}" | sed '/^[[:space:]]*$/N;/^\n$/D' > "${OUTPUT_PATH}"
fi

if [ ! -s "${OUTPUT_PATH}" ]; then
    sed "s/{{VERSION}}/${VERSION_VALUE}/g" "${TEMPLATE_PATH}" > "${OUTPUT_PATH}"
fi

echo "${OUTPUT_PATH}"
