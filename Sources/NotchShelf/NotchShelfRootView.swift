import SwiftUI

struct NotchShelfRootView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

            if store.isExpanded {
                ExpandedSpotifyView(store: store, actions: actions)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                CollapsedSpotifyPillView(store: store, actions: actions)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: store.isExpanded ? 24 : 19, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: store.isExpanded ? 24 : 19, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.32), radius: 18, x: 0, y: 12)
        .animation(.easeInOut(duration: 0.16), value: store.isExpanded)
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
                label: store.isPinned ? "Unpin" : "Pin",
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
