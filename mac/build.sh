#!/bin/bash
# Builds Archie.app using only Apple's Command Line Tools (xcode-select --install). No Xcode needed.
#
#   ./build.sh                                   # demo mode only
#   ./build.sh 1234-abcd.apps.googleusercontent.com   # with Google Tasks sync (an iOS-type client ID; see README)
#
# Optional: BUNDLE_ID=com.yourname.archie ./build.sh …   (must match the bundle ID on the Google client)
set -euo pipefail
cd "$(dirname "$0")"

CLIENT_ID="${1:-}"
BUNDLE_ID="${BUNDLE_ID:-com.archie.widget}"
APP="build/Archie.app"

if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Swift isn't installed. Run:  xcode-select --install   then try again." >&2
  exit 1
fi
if [ ! -f ../index.html ]; then
  echo "Can't find ../index.html (keep this mac folder next to index.html)." >&2
  exit 1
fi

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/web"
sed -e "s|__GOOGLE_CLIENT_ID__|$CLIENT_ID|" -e "s|__BUNDLE_ID__|$BUNDLE_ID|" Info.plist > "$APP/Contents/Info.plist"
cp ../index.html "$APP/Contents/Resources/web/index.html"

echo "Compiling…"
xcrun swiftc -O -parse-as-library \
  -target "$(uname -m)-apple-macos12.0" \
  -o "$APP/Contents/MacOS/Archie" \
  Sources/*.swift

# Ad-hoc signature so macOS will run it on this Mac and let it use the Keychain.
codesign --force --sign - "$APP" >/dev/null

echo "Done: $(pwd)/$APP"
echo "Drag it into Applications, then open it. (First launch: right-click → Open.)"
