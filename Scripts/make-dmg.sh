#!/bin/sh
# Builds CopyStack in Release and packages it as build/CopyStack-<version>.dmg.
set -eu

cd "$(dirname "$0")/.."
BUILD=build

xcodegen generate
xcodebuild -project CopyStack.xcodeproj -scheme CopyStack -configuration Release \
  -derivedDataPath "$BUILD/DerivedData" clean build

APP="$BUILD/DerivedData/Build/Products/Release/CopyStack.app"
codesign --verify --strict "$APP"

VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
STAGE="$BUILD/dmg"
DMG="$BUILD/CopyStack-$VERSION.dmg"

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname CopyStack -srcfolder "$STAGE" -format UDZO "$DMG"
rm -rf "$STAGE"
# A leftover CopyStack.app shows up as a duplicate in Spotlight.
rm -rf "$BUILD/DerivedData"

echo "$DMG"
