# NotchShelf

NotchShelf is a native macOS utility experiment inspired by the idea of using the notch/menu-bar area as a small command surface.

This project does not copy NotchNook's branding, assets, or UI. It starts with a from-scratch AppKit/SwiftUI implementation:

- Floating top-center panel
- Collapsed notch-style pill
- Expandable utility surface
- Menu bar status item
- Multi-screen repositioning
- Spotify artwork and playback controls
- Clipboard and active-app widgets
- Drag-and-drop file shelf

## Requirements

- macOS 14 or newer
- Swift toolchain from Xcode or Command Line Tools

## Run Locally

Build and launch the macOS app bundle:

```bash
make run-app
```

Build the app bundle without launching it:

```bash
make build-app
```

Verify the generated app bundle:

```bash
make verify-app
```

The app bundle is written to:

```text
.build/debug/NotchShelf.app
```

The bundle is assembled and signed in `/private/tmp` first, then copied into `.build`. This avoids macOS `codesign` failures caused by File Provider or Finder metadata in `Documents` folders.

The direct executable path is also available:

```bash
make run
```

SwiftPM is also configured:

```bash
swift run NotchShelf
```

The app runs as an accessory app. Use the menu bar icon to expand, collapse, clear shelf files, or quit.

## Spotify Widget

The Spotify widget talks to the local Spotify desktop app with macOS Apple Events. The first time you use playback controls or read current track metadata, macOS may ask for Automation permission.

If permission is denied, allow access in:

```text
System Settings > Privacy & Security > Automation
```

## Next Build Steps

- Add launch-at-login support
- Add Apple Music / system Now Playing support
- Add keyboard shortcut support
- Add settings storage
- Package as a signed `.app`/`.dmg`
- Add a full Xcode project once Xcode is selected instead of Command Line Tools
