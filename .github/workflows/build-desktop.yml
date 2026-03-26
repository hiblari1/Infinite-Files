#!/usr/bin/env bash
set -euo pipefail

DIST_DIR="dist"
APP_PATH="build/macos/Build/Products/Release/infinite_files.app"
DMG_PATH="${DIST_DIR}/InfiniteFiles.dmg"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "DMG packaging must run on macOS." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required" >&2
  exit 1
fi

flutter build macos --release

mkdir -p "$DIST_DIR"
rm -f "$DMG_PATH"

hdiutil create -volname "Infinite Files" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

echo "Created $DMG_PATH"
