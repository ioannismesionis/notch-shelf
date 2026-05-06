# NotchShelf

NotchShelf is a native macOS Spotify notch widget.

This project does not copy NotchNook's branding, assets, or UI. It is a from-scratch AppKit/SwiftUI implementation focused on Spotify:

- Floating top-center panel
- Collapsed notch-style pill
- Expandable Spotify player
- macOS-style glass visual theme
- Spotify-branded empty and fallback states
- Menu bar status item
- Multi-screen repositioning
- Launch-at-login option
- Option-Space global shortcut
- First-run setup checklist
- Custom app icon
- Pinned Spotify playlist shortcuts
- Spotify artwork, seek, volume, shuffle, repeat, playback controls, and Liked Songs heart

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

Build a release zip:

```bash
make release
```

Stop a running NotchShelf instance:

```bash
make stop
```

Rebuild and relaunch the app bundle:

```bash
make restart-app
```

Install the app into `/Applications`:

```bash
make install-app
```

Install and open the `/Applications` copy:

```bash
make open-installed-app
```

The app bundle is written to:

```text
.build/debug/NotchShelf.app
```

Release packages are written to:

```text
.build/release/
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

The app runs as an accessory app. Use the menu bar icon to expand, collapse, open Preferences, or quit.

## Preferences

Use the menu bar item to open Preferences. Settings are stored in `UserDefaults`.

Current controls:

- Start pinned
- Open at login
- Option-Space shortcut
- Show first-run setup
- Refresh interval
- Spotify Client ID
- Pinned playlists

The pin controls persistence: pinned keeps NotchShelf visible when the pointer leaves; unpinned hides it after the pointer leaves the top-center notch/menu-bar area and opens it expanded when the pointer returns.

## Spotify Widget

The Spotify widget talks to the local Spotify desktop app with macOS Apple Events. The first time you use playback controls or read current track metadata, macOS may ask for Automation permission.

If permission is denied, allow access in:

```text
System Settings > Privacy & Security > Automation
```

The Liked Songs heart uses Spotify Web API OAuth with PKCE and stores the OAuth refresh token in Keychain. To enable it:

1. Create an app in the Spotify Developer Dashboard.
2. Add this Redirect URI to the Spotify app settings:

```text
notchshelf://spotify-auth
```

3. Copy the Spotify app Client ID into NotchShelf Preferences.
4. Click the heart button in NotchShelf and approve library access.

Requested Spotify scopes:

```text
user-library-read user-library-modify playlist-read-private playlist-read-collaborative
```

Playback controls include previous, play/pause, next, shuffle, repeat, a seekable progress bar, and a compact volume slider.

Pinned playlists can be loaded and selected from Preferences. The expanded notch shows up to five playlist shortcuts.

## Next Build Steps

- Add Apple Music / system Now Playing support
- Package as a notarized `.dmg`
- Add a full Xcode project once Xcode is selected instead of Command Line Tools
