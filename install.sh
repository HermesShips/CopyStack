#!/bin/sh
# Builds CopyStack from this folder and installs it to /Applications.
# Usage: ./install.sh [--build-only]
set -eu

cd "$(dirname "$0")"

fail() {
  echo "error: $1" >&2
  exit 1
}

# First value for a key in project.yml; the app target comes before the test target.
setting() {
  sed -n "s/^[[:space:]]*$1:[[:space:]]*\"\{0,1\}\([^\"]*\)\"\{0,1\}[[:space:]]*$/\1/p" project.yml | head -n 1
}

NAME=CopyStack
BUNDLE_ID=$(setting PRODUCT_BUNDLE_IDENTIFIER)
VERSION=$(setting MARKETING_VERSION)
BUILD_NUMBER=$(setting CURRENT_PROJECT_VERSION)
MIN_MACOS=$(setting macOS)
[ -n "$BUNDLE_ID" ] && [ -n "$VERSION" ] && [ -n "$BUILD_NUMBER" ] && [ -n "$MIN_MACOS" ] \
  || fail "could not read the build settings from project.yml."

version_at_least() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -n 1)" = "$2" ]
}

MACOS=$(sw_vers -productVersion)
version_at_least "$MACOS" "$MIN_MACOS" || fail "CopyStack needs macOS $MIN_MACOS or later. This Mac has $MACOS."

xcode-select -p >/dev/null 2>&1 && xcrun --find swiftc >/dev/null 2>&1 \
  || fail "the Swift compiler is missing. Run: xcode-select --install"

SWIFT=$(xcrun swiftc --version 2>&1 | sed -n 's/.*Swift version \([0-9][0-9.]*\).*/\1/p' | head -n 1)
version_at_least "${SWIFT:-0}" 6.0 \
  || fail "CopyStack needs Swift 6 or later. This Mac has Swift ${SWIFT:-unknown}. Update Command Line Tools in System Settings > General > Software Update."

APP="build/install/$NAME.app"
echo "Building $NAME $VERSION..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

xcrun swiftc -O -swift-version 6 -module-name "$NAME" \
  -target "$(uname -m)-apple-macos$MIN_MACOS" \
  -o "$APP/Contents/MacOS/$NAME" \
  CopyStack/*.swift Core/*.swift

cp CopyStack/AppIcon.icns "$APP/Contents/Resources/"
sed -e "s/\$(EXECUTABLE_NAME)/$NAME/" \
    -e "s/\$(PRODUCT_NAME)/$NAME/" \
    -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/$BUNDLE_ID/" \
    -e "s/\$(MARKETING_VERSION)/$VERSION/" \
    -e "s/\$(CURRENT_PROJECT_VERSION)/$BUILD_NUMBER/" \
    -e "s/\$(MACOSX_DEPLOYMENT_TARGET)/$MIN_MACOS/" \
    CopyStack/Info.plist > "$APP/Contents/Info.plist"
! grep -q '\$(' "$APP/Contents/Info.plist" || fail "Info.plist has a build variable this script does not fill in."

# A downloaded ZIP marks every file as quarantined, and cp keeps that mark.
xattr -cr "$APP"
codesign --force --sign - --options runtime --identifier "$BUNDLE_ID" \
  --entitlements CopyStack/CopyStack.entitlements "$APP"
codesign --verify --strict "$APP"

if [ "${1:-}" = "--build-only" ]; then
  echo "Built $APP"
  exit 0
fi

TARGET="/Applications/$NAME.app"
[ -w /Applications ] || fail "you cannot write to /Applications. Sign in as an administrator, then run this again."
[ ! -e "$TARGET" ] || [ -w "$TARGET" ] || fail "$TARGET belongs to another user. Delete it in Finder, then run this again."

if pgrep -x "$NAME" >/dev/null; then
  echo "Quitting the running $NAME..."
  pkill -x "$NAME"
  while pgrep -x "$NAME" >/dev/null; do sleep 0.2; done
fi

rm -rf "$TARGET"
ditto "$APP" "$TARGET"
rm -rf "$APP"
open "$TARGET"

echo "Installed $TARGET. Look for the stack icon in the menu bar."
