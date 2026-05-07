import SwiftUI

struct NotchShelfRootView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions

    var body: some View {
        let cornerRadius: CGFloat = store.isExpanded ? 28 : 21
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let theme = SpotifyTheme(track: store.spotifyStatus.track)

        ZStack {
            Color.clear

            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

                LinearGradient(
                    colors: [
                        theme.surfaceTop,
                        theme.surfaceMiddle,
                        theme.surfaceBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Color.black.opacity(0.14)

                if store.isExpanded {
                    ExpandedSpotifyView(store: store, actions: actions, theme: theme)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    CollapsedSpotifyPillView(store: store, actions: actions, theme: theme)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .clipShape(shape)
            .overlay(
                shape
                    .strokeBorder(theme.cardBorder, lineWidth: 1)
            )
            .overlay(
                shape
                    .strokeBorder(Color.black.opacity(0.20), lineWidth: 0.5)
                    .blendMode(.overlay)
            )
            .compositingGroup()
            .shadow(color: .black.opacity(0.20), radius: 14, x: 0, y: 8)
            .padding(.top, 2)
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: store.isExpanded)
        .animation(.easeInOut(duration: 0.22), value: store.spotifyStatus.track?.artworkURL ?? "")
        .onHover(perform: actions.setHovering)
    }
}

private struct CollapsedSpotifyPillView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions
    let theme: SpotifyTheme
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 9) {
            ZStack(alignment: .bottomTrailing) {
                if let track = store.spotifyStatus.track {
                    AlbumArtworkView(track: track)
                        .frame(width: 68, height: 68)
                        .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 5)
                        .help("\(track.title) by \(track.artist)")
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(theme.iconTileBackground)
                        .frame(width: 68, height: 68)
                        .overlay(SpotifyLogoView(size: 34))
                }

                MiniControlButton(
                    systemName: "arrow.up.left.and.arrow.down.right",
                    label: "Expand",
                    theme: theme,
                    action: actions.toggleExpanded
                )
                .offset(x: 23, y: 4)
            }
            .frame(height: 72)

            HStack(spacing: 9) {
                if let track = store.spotifyStatus.track {
                    MiniControlButton(
                        systemName: "backward.fill",
                        label: "Previous",
                        theme: theme,
                        action: actions.spotifyPrevious
                    )

                    MiniControlButton(
                        systemName: track.playbackState.isPlaying ? "pause.fill" : "play.fill",
                        label: track.playbackState.isPlaying ? "Pause" : "Play",
                        isPrimary: true,
                        theme: theme,
                        action: actions.spotifyPlayPause
                    )

                    MiniControlButton(
                        systemName: "forward.fill",
                        label: "Next",
                        theme: theme,
                        action: actions.spotifyNext
                    )
                } else {
                    MiniControlButton(
                        systemName: "arrow.up.forward.app",
                        label: collapsedEmptyText,
                        isPrimary: true,
                        theme: theme,
                        action: actions.spotifyOpen
                    )
                }
            }

            if let track = store.spotifyStatus.track {
                Text(track.title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(1)
                    .frame(maxWidth: 128)
            } else {
                Text(collapsedEmptyText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.66))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 8)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .background(isHovering ? theme.controlHoverBackground : Color.clear)
        .scaleEffect(isHovering ? 1.015 : 1)
        .animation(.easeInOut(duration: 0.14), value: isHovering)
        .onHover { isHovering = $0 }
    }

    private var collapsedEmptyText: String {
        switch store.spotifyStatus.availability {
        case .notRunning:
            return "Open Spotify"
        case .permissionDenied:
            return "Needs permission"
        default:
            return "Nothing playing"
        }
    }
}

private struct ExpandedSpotifyView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions
    let theme: SpotifyTheme

    var body: some View {
        VStack(spacing: 13) {
            header

            if store.isFirstRunSetupVisible {
                FirstRunSetupView(store: store, actions: actions, theme: theme)
            } else {
                SpotifyWidgetView(
                    status: store.spotifyStatus,
                    savedTrackStatus: store.savedTrackStatus,
                    actions: actions,
                    theme: theme
                )

                if !store.pinnedPlaylists.isEmpty {
                    PinnedPlaylistsStrip(
                        playlists: store.pinnedPlaylists,
                        theme: theme,
                        onOpen: actions.spotifyOpenPlaylist
                    )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                SpotifyLogoView(size: 18)

                Text("Spotify")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)

            Spacer()

            if !store.isFirstRunSetupVisible {
                IconButton(
                    systemName: "arrow.down.right.and.arrow.up.left",
                    label: "Collapse to mini player",
                    theme: theme,
                    action: actions.toggleExpanded
                )
            }

            IconButton(
                systemName: store.isPinned ? "pin.fill" : "pin",
                label: store.isPinned ? "Unpin" : "Keep visible",
                theme: theme,
                action: actions.togglePinned
            )
        }
    }
}

private struct PinnedPlaylistsStrip: View {
    let playlists: [SpotifyPlaylist]
    let theme: SpotifyTheme
    let onOpen: (SpotifyPlaylist) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.58))

            ForEach(playlists.prefix(5)) { playlist in
                PinnedPlaylistButton(playlist: playlist, theme: theme) {
                    onOpen(playlist)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(height: 34)
    }
}

private struct PinnedPlaylistButton: View {
    let playlist: SpotifyPlaylist
    let theme: SpotifyTheme
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 8, weight: .bold))

                Text(playlist.name)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: 108)
            .frame(height: 28)
            .padding(.horizontal, 9)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(isHovering ? 0.96 : 0.78))
        .background(isHovering ? theme.controlHoverBackground : theme.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .scaleEffect(isHovering ? 1.04 : 1)
        .animation(.easeInOut(duration: 0.13), value: isHovering)
        .onHover { isHovering = $0 }
        .help("Open \(playlist.name)")
    }
}

private struct MiniControlButton: View {
    let systemName: String
    let label: String
    var isPrimary = false
    let theme: SpotifyTheme
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: isPrimary ? 11 : 10, weight: .bold))
                .frame(width: isPrimary ? 30 : 26, height: isPrimary ? 30 : 26)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isPrimary ? theme.primaryControlForeground : .white.opacity(isHovering ? 0.96 : 0.76))
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: isPrimary ? 10 : 8, style: .continuous))
        .scaleEffect(isHovering ? 1.06 : 1)
        .animation(.easeInOut(duration: 0.13), value: isHovering)
        .onHover { isHovering = $0 }
        .help(label)
    }

    private var buttonBackground: Color {
        if isPrimary {
            return isHovering ? Color.white.opacity(0.92) : theme.primaryControlBackground
        }

        return isHovering ? theme.controlHoverBackground : theme.controlBackground
    }
}

private struct IconButton: View {
    let systemName: String
    let label: String
    let theme: SpotifyTheme
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(isHovering ? 0.98 : 0.82))
        .background(isHovering ? theme.controlHoverBackground : theme.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .scaleEffect(isHovering ? 1.06 : 1)
        .animation(.easeInOut(duration: 0.13), value: isHovering)
        .onHover { isHovering = $0 }
        .help(label)
    }
}
