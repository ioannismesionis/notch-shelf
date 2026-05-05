import SwiftUI

struct NotchShelfRootView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions

    var body: some View {
        let cornerRadius: CGFloat = store.isExpanded ? 28 : 21
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            Color.clear

            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.11),
                        Color.black.opacity(0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Color.black.opacity(0.22)

                if store.isExpanded {
                    ExpandedSpotifyView(store: store, actions: actions)
                        .transition(.opacity.combined(with: .scale(scale: 0.985)))
                } else {
                    CollapsedSpotifyPillView(store: store, actions: actions)
                        .transition(.opacity.combined(with: .scale(scale: 0.985)))
                }
            }
            .clipShape(shape)
            .overlay(
                shape
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
            .overlay(
                shape
                    .strokeBorder(Color.black.opacity(0.28), lineWidth: 0.5)
                    .blendMode(.overlay)
            )
            .compositingGroup()
            .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)
            .padding(.top, 2)
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .animation(.easeInOut(duration: 0.18), value: store.isExpanded)
        .onHover(perform: actions.setHovering)
    }
}

private struct CollapsedSpotifyPillView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions

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
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

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
    }
}

private struct ExpandedSpotifyView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions

    var body: some View {
        VStack(spacing: 13) {
            header
            SpotifyWidgetView(status: store.spotifyStatus, actions: actions)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: 15, weight: .semibold))
                Text("Spotify")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)

            Spacer()

            IconButton(
                systemName: store.isPinned ? "pin.fill" : "pin",
                label: store.isPinned ? "Hide when pointer leaves" : "Keep visible",
                action: actions.togglePinned
            )

            IconButton(systemName: "minus", label: "Collapse", action: actions.toggleExpanded)
        }
    }
}

private struct IconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.82))
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(label)
    }
}
