# CopyStack

A menu-bar clipboard history for macOS. It keeps your recent text copies, 25 by default. Pick an earlier copy, then paste it yourself with ⌘V.

Requires macOS 13 or later.

## Install

1. Open `CopyStack-<version>.dmg`.
2. Drag `CopyStack` onto `Applications`.
3. Open CopyStack from `Applications`. A stack icon shows in the menu bar.

### First launch on another Mac

The build is ad-hoc signed, not Developer ID signed. Gatekeeper blocks the first launch. Approve it once:

1. Open CopyStack. macOS says it cannot verify the app. Click **Done**.
2. Within an hour, open **System Settings → Privacy & Security**.
3. Scroll to **Security**, find the CopyStack message, and click **Open Anyway**.
4. Confirm the dialog and authenticate.

From the terminal, `xattr -dr com.apple.quarantine /Applications/CopyStack.app` does the same.

## Build

The `.xcodeproj` is generated from `project.yml` and is not tracked. After a fresh clone:

```
brew install xcodegen
xcodegen generate
open CopyStack.xcodeproj
```

Re-run `xcodegen generate` after every edit to `project.yml`.

The app icon is generated, not drawn: `swift Scripts/make-app-icon.swift <dir>`, then `iconutil -c icns <dir> -o CopyStack/AppIcon.icns`.

## Package

```
Scripts/make-dmg.sh
```

Builds Release and writes `build/CopyStack-<version>.dmg`. The version comes from `MARKETING_VERSION` in `project.yml`.

## Test

```
xcodebuild -project CopyStack.xcodeproj -scheme CopyStack -destination 'platform=macOS' test
```

## Not in v1

Parked ideas live in [`docs/future.md`](docs/future.md).
