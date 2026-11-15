#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT_DIR/build/ApiumQuickLookHost.app"
DIST="$ROOT_DIR/dist"
ZIP_NAME="ApiumSlicerFinderPreview-macos-universal.zip"

[[ -d "$APP" ]] || { echo "error: build the Release app first" >&2; exit 1; }
for binary in \
  "$APP/Contents/MacOS/ApiumQuickLookHost" \
  "$APP/Contents/PlugIns/ApiumQuickLookThumbnailExtension.appex/Contents/MacOS/ApiumQuickLookThumbnailExtension" \
  "$APP/Contents/PlugIns/ApiumQuickLookPreviewExtension.appex/Contents/MacOS/ApiumQuickLookPreviewExtension"; do
  lipo "$binary" -verify_arch arm64 x86_64
done
mkdir -p "$DIST"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/ApiumQuickLookHost.app"
APP="$STAGING/ApiumQuickLookHost.app"
# Ad-hoc signatures allow local execution on Apple Silicon. Developer ID
# signing/notarization is a separate distribution step requiring Apple credentials.
for extension in Thumbnail Preview; do
  codesign --force --sign - --timestamp=none \
    --entitlements "$ROOT_DIR/Extensions/${extension}Extension/${extension}Extension.entitlements" \
    "$APP/Contents/PlugIns/ApiumQuickLook${extension}Extension.appex"
done
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"
cp "$ROOT_DIR/LICENSE" "$ROOT_DIR/README.md" "$STAGING/"
rm -f "$DIST/$ZIP_NAME"
ditto -c -k --sequesterRsrc "$STAGING" "$DIST/$ZIP_NAME"
(cd "$DIST" && shasum -a 256 "$ZIP_NAME" > SHA256SUMS.txt)
echo "[package] $DIST/$ZIP_NAME"
