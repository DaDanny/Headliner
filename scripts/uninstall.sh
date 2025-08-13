#!/usr/bin/env bash
set -euo pipefail

TEAM_ID="378NGS49HA"
EXT_BUNDLE_ID="com.dannyfrancken.Headliner.CameraExtension"
APP_NAME="Headliner"

echo "→ Quitting main app..."
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true

echo "→ Uninstalling extension $EXT_BUNDLE_ID..."
sudo systemextensionsctl uninstall "$TEAM_ID" "$EXT_BUNDLE_ID" || true

echo "→ Verifying uninstall..."
if systemextensionsctl list | grep -q "$EXT_BUNDLE_ID"; then
  echo "   ⚠️ Still listed—make sure all apps using the camera are closed."
else
  echo "   ✅ Not listed."
fi