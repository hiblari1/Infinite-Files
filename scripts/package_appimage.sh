#!/usr/bin/env bash
set -euo pipefail

APP_NAME="InfiniteFiles"
APP_DIR="build/linux/x64/release/bundle"
DIST_DIR="dist"
APPIMAGE_TOOL="appimagetool"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required" >&2
  exit 1
fi

if ! command -v "$APPIMAGE_TOOL" >/dev/null 2>&1; then
  echo "appimagetool is required and not found in PATH" >&2
  exit 1
fi

flutter build linux --release

mkdir -p "$DIST_DIR"
TMP_APPDIR="${DIST_DIR}/${APP_NAME}.AppDir"
rm -rf "$TMP_APPDIR"
mkdir -p "$TMP_APPDIR/usr/bin"
cp -R "$APP_DIR"/* "$TMP_APPDIR/usr/bin/"

cat >"$TMP_APPDIR/${APP_NAME}.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Infinite Files
Exec=infinite_files
Icon=infinite_files
Categories=Utility;FileManager;
DESKTOP

if [ -f "$APP_DIR/data/flutter_assets/assets/icon.png" ]; then
  cp "$APP_DIR/data/flutter_assets/assets/icon.png" "$TMP_APPDIR/infinite_files.png"
else
  touch "$TMP_APPDIR/infinite_files.png"
fi

"$APPIMAGE_TOOL" "$TMP_APPDIR" "${DIST_DIR}/${APP_NAME}-x86_64.AppImage"
echo "Created ${DIST_DIR}/${APP_NAME}-x86_64.AppImage"
