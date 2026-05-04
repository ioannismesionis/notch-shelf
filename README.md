# NotchShelf

NotchShelf is a native macOS utility experiment inspired by the idea of using the notch/menu-bar area as a small command surface.

This project does not copy NotchNook's branding, assets, or UI. It starts with a from-scratch AppKit/SwiftUI implementation:

- Floating top-center panel
- Collapsed notch-style pill
- Expandable utility surface
- Menu bar status item
- Multi-screen repositioning
- Clipboard and active-app widgets
- Drag-and-drop file shelf

## Requirements

- macOS 14 or newer
- Swift toolchain from Xcode or Command Line Tools

## Run Locally

The direct compiler path is currently the most reliable option on this machine:

```bash
make run
```

SwiftPM is also configured:

```bash
swift run NotchShelf
```

The app runs as an accessory app. Use the menu bar icon to expand, collapse, clear shelf files, or quit.

## Next Build Steps

- Add launch-at-login support
- Add real media controls
- Add keyboard shortcut support
- Add settings storage
- Package as a signed `.app`/`.dmg`
- Add a full Xcode project once Xcode is selected instead of Command Line Tools
