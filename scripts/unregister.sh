#!/usr/bin/env bash
set -euo pipefail
APP="${1:-${INSTALL_PATH:-$HOME/Applications/ApiumQuickLookHost.app}}"
[[ -d "$APP" && "$APP" == /* && "$APP" == *.app ]] || { echo "error: supply an installed app's absolute path" >&2; exit 1; }
bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")
[[ "$bundle_id" == com.apium.quicklook.host ]] || { echo "error: this is not the Apium Quick Look host" >&2; exit 1; }
for extension in "$APP"/Contents/PlugIns/*.appex; do pluginkit -r "$extension"; done
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$APP"
qlmanage -r
qlmanage -r cache
echo "[unregister] Unregistered: $APP (move the app to Trash to finish removal)"
