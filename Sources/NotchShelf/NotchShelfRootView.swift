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
                        .transition(.opacity.combined(with: .scale(scale: 0.985)))
                } else {
                    CollapsedSpotifyPillView(store: store, actions: actions, theme: theme)
                        .transition(.opacity.combined(with: .scale(scale: 0.985)))
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
        .animation(.easeInOut(duration: 0.18), value: store.isExpanded)
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
        HStack(spacing: 10) {
            Button(action: actions.toggleExpanded) {
                HStack(spacing: 9) {
                    if let track = store.spotifyStatus.track {
                        AlbumArtworkView(track: track)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(track.title)
                                .font(.system(size: 12, weight: .bold))
                                .lineLimit(1)
                                .truncationMode(.tail)

                            HStack(spacing: 6) {
                                PlaybackBars(isPlaying: track.playbackState.isPlaying)

                                Text(track.playbackState.isPlaying ? track.artist : "Paused")
                                    .font(.system(size: 10, weight: .semibold))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundStyle(.white.opacity(0.58))
                            }

                            MiniProgressBar(progress: track.progress, theme: theme)
                        }
                        .foregroundStyle(.white)
                    } else {
                        SpotifyLogoView(size: 22)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Spotify")
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)

                            Text(collapsedEmptyText)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .foregroundStyle(.white.opacity(0.58))
                        }
                        .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let track = store.spotifyStatus.track {
                Button(action: actions.spotifyPlayPause) {
                    Image(systemName: track.playbackState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.primaryControlForeground)
                        .frame(width: 28, height: 28)
                        .background(theme.primaryControlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(track.playbackState.isPlaying ? "Pause" : "Play")
            }
        }
        .padding(.horizontal, 13)
        .buttonStyle(.plain)
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

            IconButton(
                systemName: store.isPinned ? "pin.fill" : "pin",
                label: store.isPinned ? "Unpin" : "Keep visible",
                theme: theme,
                action: actions.togglePinned
            )
        }
    }
}

private struct MiniProgressBar: View {
    let progress: Double
    let theme: SpotifyTheme

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))

                Capsule()
                    .fill(theme.progressFill)
                    .frame(width: max(3, proxy.size.width * progress))
            }
        }
        .frame(height: 3)
    }
}

private struct PlaybackBars: View {
    let isPlaying: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(isPlaying ? 0.76 : 0.38))
                    .frame(width: 2, height: isPlaying ? CGFloat(5 + index * 2) : 4)
            }
        }
        .frame(width: 10, height: 10)
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
