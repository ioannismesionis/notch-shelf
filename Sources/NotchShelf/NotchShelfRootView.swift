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
        Button(action: actions.toggleExpanded) {
            HStack(spacing: 9) {
                if let track = store.spotifyStatus.track {
                    AlbumArtworkView(track: track)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text(track.playbackState.isPlaying ? track.artist : "Paused")
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                        .foregroundStyle(.white)
                } else {
                    SpotifyLogoView(size: 20)

                    Text("Spotify")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovering ? theme.controlHoverBackground : Color.clear)
        .scaleEffect(isHovering ? 1.015 : 1)
        .animation(.easeInOut(duration: 0.14), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

private struct ExpandedSpotifyView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions
    let theme: SpotifyTheme

    var body: some View {
        VStack(spacing: 13) {
            header
            SpotifyWidgetView(status: store.spotifyStatus, actions: actions, theme: theme)
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
