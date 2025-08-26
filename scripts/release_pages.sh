#!/usr/bin/env bash
set -euo pipefail

### ── CONFIG ──────────────────────────────────────────────────────────────
APP_PRODUCT_NAME="Headliner"                          # as shown in .app
APP_BUNDLE_PATH="Release/${APP_PRODUCT_NAME}.app"     # adjust if different
OUTPUT_DIR="docs/updates"                             # served by GitHub Pages
ARCHIVE_NAME="${APP_PRODUCT_NAME}.zip"                # Sparkle likes .zip
SPARKLE_BIN="/usr/local/bin"                          # folder containing sign_update
MIN_SYSTEM_VERSION="13.0"                             # optional for feed
# Repo → used to build your public feed base URL:
GITHUB_USER="DaDanny"
GITHUB_REPO="Headliner"
FEED_BASE_URL="https://${GITHUB_USER}.github.io/${GITHUB_REPO}"
FEED_URL="${FEED_BASE_URL}/updates/appcast.xml"
ENCLOSURE_URL="${FEED_BASE_URL}/updates/${ARCHIVE_NAME}"

# If your Sparkle tools aren’t in PATH, add:
export PATH="$SPARKLE_BIN:$PATH"

### ── VERIFY TOOLS ────────────────────────────────────────────────────────
command -v sign_update >/dev/null || { echo "❌ sign_update not found in PATH/SPARKLE_BIN"; exit 1; }

### ── READ VERSION INFO FROM APP ─────────────────────────────────────────
# Pull CFBundleShortVersionString and CFBundleVersion from the built app
read_plist () { /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null || plutil -p "$1" | awk -v key="$2" -F'=> ' '$0~key{gsub(/[",]/,"",$2);print $2}'; }
INFO_PLIST="${APP_BUNDLE_PATH}/Contents/Info.plist"
[[ -f "$INFO_PLIST" ]] || { echo "❌ $INFO_PLIST not found. Build your app first."; exit 1; }
SHORT_VER=$(read_plist "$INFO_PLIST" "CFBundleShortVersionString")
BUILD_VER=$(read_plist "$INFO_PLIST" "CFBundleVersion")

echo "ℹ️  Version: ${SHORT_VER}  (build ${BUILD_VER})"

### ── PACKAGE .app → .zip ────────────────────────────────────────────────
rm -f "${OUTPUT_DIR}/${ARCHIVE_NAME}"
mkdir -p "$OUTPUT_DIR"
pushd "$(dirname "$APP_BUNDLE_PATH")" >/dev/null
zip -ry "${ARCHIVE_NAME}" "$(basename "$APP_BUNDLE_PATH")"
BYTES=$(stat -f%z "${ARCHIVE_NAME}")
popd >/dev/null
mv "$(dirname "$APP_BUNDLE_PATH")/${ARCHIVE_NAME}" "${OUTPUT_DIR}/"

### ── SIGN THE ARCHIVE FOR SPARKLE ───────────────────────────────────────
# This prints "sparkle:edSignature=...."
SIG_RAW=$(sign_update "${OUTPUT_DIR}/${ARCHIVE_NAME}")
# extract the base64 signature (last field or value after '=')
if [[ "$SIG_RAW" == *"edSignature="* ]]; then
  SIG=$(echo "$SIG_RAW" | sed -E 's/.*edSignature="?([^" ]+).*/\1/')
else
  SIG=$(echo "$SIG_RAW" | awk '{print $NF}')
fi
[[ -n "${SIG:-}" ]] || { echo "❌ Could not parse Sparkle edSignature"; exit 1; }
echo "✅ Sparkle signature: $SIG"

### ── WRITE appcast.xml (single latest item) ─────────────────────────────
APPCAST="${OUTPUT_DIR}/appcast.xml"
cat > "$APPCAST" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"
     xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"
     xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>${APP_PRODUCT_NAME} Updates</title>
    <link>${FEED_URL}</link>
    <description>Latest updates for ${APP_PRODUCT_NAME}</description>

    <item>
      <title>v${SHORT_VER}</title>
      <sparkle:minimumSystemVersion>${MIN_SYSTEM_VERSION}</sparkle:minimumSystemVersion>
      <enclosure
        url="${ENCLOSURE_URL}"
        sparkle:shortVersionString="${SHORT_VER}"
        sparkle:version="${BUILD_VER}"
        sparkle:edSignature="${SIG}"
        length="${BYTES}"
        type="application/octet-stream" />
      <pubDate>$(LC_ALL=C date -u +"%a, %d %b %Y %T %z")</pubDate>
      <sparkle:releaseNotesLink>${FEED_BASE_URL}/updates/release-notes-${SHORT_VER}.html</sparkle:releaseNotesLink>
    </item>
  </channel>
</rss>
XML

### ── OPTIONAL: GENERATE SIMPLE RELEASE NOTES STUB ───────────────────────
NOTES="${OUTPUT_DIR}/release-notes-${SHORT_VER}.html"
if [[ ! -f "$NOTES" ]]; then
  cat > "$NOTES" <<HTML
<!doctype html><meta charset="utf-8">
<title>${APP_PRODUCT_NAME} ${SHORT_VER} – Release Notes</title>
<style>body{font:16px -apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif;margin:24px;line-height:1.5}</style>
<h1>${APP_PRODUCT_NAME} ${SHORT_VER}</h1>
<ul>
  <li>Improvements and bug fixes.</li>
</ul>
HTML
fi

### ── DONE ────────────────────────────────────────────────────────────────
echo "✅ Appcast: ${APPCAST}"
echo "✅ Archive: ${OUTPUT_DIR}/${ARCHIVE_NAME}"
echo "👉 Commit & push to main. Ensure GitHub Pages source = /docs"
echo "👉 Info.plist SUFeedURL should be: ${FEED_URL}"