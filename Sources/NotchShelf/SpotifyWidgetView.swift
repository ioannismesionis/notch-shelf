import SwiftUI

struct SpotifyWidgetView: View {
    let status: SpotifyStatus
    let actions: ShelfActions

    var body: some View {
        Group {
            if let track = status.track {
                player(track)
            } else {
                unavailableState
            }
        }
        .frame(height: 96)
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func player(_ track: SpotifyTrack) -> some View {
        HStack(spacing: 12) {
            AlbumArtworkView(track: track)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 9) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(track.artist)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.66))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                VStack(spacing: 5) {
                    ProgressBar(progress: track.progress)

                    HStack {
                        Text(track.elapsedText)
                        Spacer()
                        Text(track.remainingText)
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
                }
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    SpotifyButton(systemName: "backward.fill", label: "Previous", action: actions.spotifyPrevious)
                    SpotifyButton(
                        systemName: track.playbackState.isPlaying ? "pause.fill" : "play.fill",
                        label: track.playbackState.isPlaying ? "Pause" : "Play",
                        isPrimary: true,
                        action: actions.spotifyPlayPause
                    )
                    SpotifyButton(systemName: "forward.fill", label: "Next", action: actions.spotifyNext)
                }

                Button(action: actions.spotifyOpen) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 34, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.72))
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .help("Open Spotify")
            }
        }
        .padding(12)
    }

    private var unavailableState: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.10))

                Image(systemName: "music.note")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text("Spotify")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }

            Spacer()

            Button(action: actions.spotifyOpen) {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 38, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .help("Open Spotify")
        }
        .padding(12)
    }

    private var statusText: String {
        switch status.availability {
        case .available:
            return "Ready"
        case .notRunning:
            return "Not running"
        case .noTrack:
            return "No track"
        case .permissionDenied:
            return "Allow Automation access"
        case .error(let message):
            return message
        }
    }
}

struct AlbumArtworkView: View {
    let track: SpotifyTrack

    var body: some View {
        ZStack {
            if let artwork = track.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "music.note")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.74))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.14))

                Capsule()
                    .fill(Color.white.opacity(0.88))
                    .frame(width: max(4, proxy.size.width * progress))
            }
        }
        .frame(height: 5)
    }
}

private struct SpotifyButton: View {
    let systemName: String
    let label: String
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: isPrimary ? 13 : 11, weight: .bold))
                .frame(width: isPrimary ? 34 : 28, height: isPrimary ? 32 : 28)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isPrimary ? .black : .white.opacity(0.78))
        .background(isPrimary ? Color.white : Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: isPrimary ? 10 : 8, style: .continuous))
        .help(label)
    }
}
