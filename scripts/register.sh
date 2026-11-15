#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${1:-$ROOT_DIR/build/ApiumQuickLookHost.app}"
DEST="${INSTALL_PATH:-$HOME/Applications/ApiumQuickLookHost.app}"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
[[ -d "$SOURCE" ]] || { echo "error: app not found: $SOURCE" >&2; exit 1; }
SOURCE="$(cd "$SOURCE" && pwd -P)"
if [[ -d "$DEST" ]]; then DEST="$(cd "$DEST" && pwd -P)"; fi
source_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SOURCE/Contents/Info.plist")
[[ "$source_id" == com.apium.quicklook.host ]] || { echo "error: source is not the Apium Quick Look host" >&2; exit 1; }
[[ "$DEST" == /* && "$DEST" == *.app && "$SOURCE" != "$DEST" ]] || { echo "error: use a separate absolute .app installation path" >&2; exit 1; }
if [[ -e "$DEST" ]]; then
  bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEST/Contents/Info.plist")
  [[ "$bundle_id" == com.apium.quicklook.host ]] || { echo "error: destination belongs to another app" >&2; exit 1; }
  "$LSREGISTER" -u "$DEST"
  rm -rf "$DEST"
fi
mkdir -p "$(dirname "$DEST")"
ditto "$SOURCE" "$DEST"
"$LSREGISTER" -f "$DEST"
for extension in "$DEST"/Contents/PlugIns/*.appex; do pluginkit -a "$extension"; done
qlmanage -r
qlmanage -r cache
echo "[register] Installed: $DEST"
