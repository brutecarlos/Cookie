#!/usr/bin/env bash
# Create a zip of the Cookie extension suitable for manual upload.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${ROOT_DIR}/cookie-extension.zip"
echo "Packaging Cookie extension into ${OUT}"
cd "${ROOT_DIR}"
# Remove previous archive
rm -f "${OUT}"
# Include all files under Cookie except node_modules, .git and store/archive
zip -r "$OUT" . -x "*.git*" "node_modules/*" "*.DS_Store" "store/screenshots/*"
echo "Created: ${OUT}"
