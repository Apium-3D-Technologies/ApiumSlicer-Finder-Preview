#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="ApiumQuickLookPreview"
PROJECT_FILE="$ROOT_DIR/${PROJECT_NAME}.xcodeproj"
PROJECT_YML="$ROOT_DIR/project.yml"
SCHEME="${SCHEME:-ApiumQuickLookHost}"
CONFIGURATION="${CONFIGURATION:-Debug}"
BUILD_DIR="$ROOT_DIR/build"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"
PRODUCTS_DIR="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION"
APP_NAME="ApiumQuickLookHost.app"
APP_SOURCE="$PRODUCTS_DIR/$APP_NAME"
APP_DEST="$BUILD_DIR/$APP_NAME"
BIN_DEST="$BUILD_DIR/ApiumQuickLookHost"
THUMB_APPEX_NAME="ApiumQuickLookThumbnailExtension.appex"
PREVIEW_APPEX_NAME="ApiumQuickLookPreviewExtension.appex"
THUMB_APPEX_SOURCE="$PRODUCTS_DIR/$THUMB_APPEX_NAME"
PREVIEW_APPEX_SOURCE="$PRODUCTS_DIR/$PREVIEW_APPEX_NAME"
THUMB_APPEX_DEST="$BUILD_DIR/$THUMB_APPEX_NAME"
PREVIEW_APPEX_DEST="$BUILD_DIR/$PREVIEW_APPEX_NAME"

mkdir -p "$BUILD_DIR"

if [[ -f "$PROJECT_YML" ]]; then
  if [[ ! -d "$PROJECT_FILE" || "${GENERATE_XCODEPROJ:-0}" == "1" ]]; then
    if ! command -v xcodegen >/dev/null 2>&1; then
      echo "error: xcodegen is required but not installed. Install with: brew install xcodegen" >&2
      exit 1
    fi

    echo "[build] Generating Xcode project from project.yml"
    (cd "$ROOT_DIR" && xcodegen generate)
  else
    echo "[build] Reusing existing Xcode project (set GENERATE_XCODEPROJ=1 to regenerate)"
  fi
fi

if [[ ! -d "$PROJECT_FILE" ]]; then
  echo "error: Xcode project not found at $PROJECT_FILE" >&2
  exit 1
fi

XCODEBUILD_ARGS=(
  -project "$PROJECT_FILE"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination 'platform=macOS'
  -derivedDataPath "$DERIVED_DATA_PATH"
  build
)

if [[ "${UNSIGNED:-0}" == "1" ]]; then
  XCODEBUILD_ARGS+=(CODE_SIGNING_ALLOWED=NO)
else
  echo "[build] Using Xcode signing configuration from project settings."
fi

echo "[build] Building $SCHEME ($CONFIGURATION)"
xcodebuild "${XCODEBUILD_ARGS[@]}"

if [[ ! -d "$APP_SOURCE" ]]; then
  echo "error: Build finished but app not found at $APP_SOURCE" >&2
  exit 1
fi

rm -rf "$APP_DEST"
cp -R "$APP_SOURCE" "$APP_DEST"

BIN_SOURCE="$APP_DEST/Contents/MacOS/ApiumQuickLookHost"
if [[ -f "$BIN_SOURCE" ]]; then
  cp "$BIN_SOURCE" "$BIN_DEST"
fi

if [[ -d "$THUMB_APPEX_SOURCE" ]]; then
  rm -rf "$THUMB_APPEX_DEST"
  cp -R "$THUMB_APPEX_SOURCE" "$THUMB_APPEX_DEST"
fi

if [[ -d "$PREVIEW_APPEX_SOURCE" ]]; then
  rm -rf "$PREVIEW_APPEX_DEST"
  cp -R "$PREVIEW_APPEX_SOURCE" "$PREVIEW_APPEX_DEST"
fi

echo "[build] App: $APP_DEST"
echo "[build] Binary: $BIN_DEST"
echo "[build] Thumbnail appex: $THUMB_APPEX_DEST"
echo "[build] Preview appex: $PREVIEW_APPEX_DEST"
