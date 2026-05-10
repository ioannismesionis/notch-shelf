import SwiftUI

struct SpotifyWidgetView: View {
    let status: SpotifyStatus
    let savedTrackStatus: SpotifySavedTrackStatus
    let actions: ShelfActions
    let theme: SpotifyTheme
    @State private var volumeOverride: Double?

    var body: some View {
        Group {
            if let track = status.track {
                player(track)
            } else {
                unavailableState
            }
        }
        .frame(height: 108)
        .background(theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(theme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func player(_ track: SpotifyTrack) -> some View {
        HStack(spacing: 12) {
            AlbumArtworkView(track: track)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
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
                    SeekableProgressBar(
                        progress: track.progress,
                        theme: theme,
                        onSeek: actions.spotifySeek
                    )

                    HStack {
                        Text(track.elapsedText)
                        Spacer()
                        Text(track.remainingText)
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
                }

                VolumeControl(
                    volume: volumeOverride ?? Double(track.volume),
                    theme: theme,
                    onVolumePreview: { volume in
                        volumeOverride = volume
                    },
                    onVolumeCommit: { volume in
                        volumeOverride = volume
                        actions.spotifySetVolume(volume)
                    }
                )
                .onChange(of: track.volume) { _, newValue in
                    volumeOverride = Double(newValue)
                }
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    SpotifyButton(
                        systemName: "shuffle",
                        label: track.isShuffling ? "Turn shuffle off" : "Turn shuffle on",
                        isActive: track.isShuffling,
                        theme: theme,
                        action: actions.spotifyToggleShuffle
                    )
                    SpotifyButton(
                        systemName: "backward.fill",
                        label: "Previous",
                        theme: theme,
                        action: actions.spotifyPrevious
                    )
                    SpotifyButton(
                        systemName: track.playbackState.isPlaying ? "pause.fill" : "play.fill",
                        label: track.playbackState.isPlaying ? "Pause" : "Play",
                        isPrimary: true,
                        theme: theme,
                        action: actions.spotifyPlayPause
                    )
                    SpotifyButton(
                        systemName: "forward.fill",
                        label: "Next",
                        theme: theme,
                        action: actions.spotifyNext
                    )
                    SpotifyButton(
                        systemName: "repeat",
                        label: track.isRepeating ? "Turn repeat off" : "Turn repeat on",
                        isActive: track.isRepeating,
                        theme: theme,
                        action: actions.spotifyToggleRepeat
                    )
                }

                HStack(spacing: 8) {
                    HeartButton(
                        status: savedTrackStatus,
                        theme: theme,
                        action: actions.spotifyToggleSavedTrack
                    )

                    SpotifyButton(
                        systemName: "arrow.up.forward.app",
                        label: "Open Spotify",
                        compact: true,
                        theme: theme,
                        action: actions.spotifyOpen
                    )
                }
            }
        }
        .padding(12)
    }

    private var unavailableState: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.iconTileBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(theme.cardBorder, lineWidth: 1)
                    )

                SpotifyStatusIcon(availability: status.availability)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(emptyTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Text(emptyMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }

            Spacer()

            EmptyStateButton(
                title: emptyButtonTitle,
                systemName: emptyButtonIconName,
                theme: theme,
                action: emptyButtonAction
            )
        }
        .padding(12)
    }

    private var emptyTitle: String {
        switch status.availability {
        case .available:
            return "Spotify Ready"
        case .notRunning:
            return "Open Spotify"
        case .noTrack:
            return "Nothing Playing"
        case .permissionDenied:
            return "Automation Needed"
        case .error:
            return "Spotify Error"
        }
    }

    private var emptyMessage: String {
        switch status.availability {
        case .available:
            return "Pick a song to show it here."
        case .notRunning:
            return "Start Spotify to show the current track."
        case .noTrack:
            return "Choose a song in Spotify."
        case .permissionDenied:
            return "Allow NotchShelf to control Spotify."
        case .error(let message):
            return message.isEmpty ? "Could not read playback state." : message
        }
    }

    private var emptyButtonTitle: String {
        switch status.availability {
        case .permissionDenied:
            return "Settings"
        default:
            return "Open"
        }
    }

    private var emptyButtonIconName: String {
        switch status.availability {
        case .permissionDenied:
            return "gearshape.fill"
        default:
            return "arrow.up.forward.app"
        }
    }

    private var emptyButtonAction: () -> Void {
        switch status.availability {
        case .permissionDenied:
            return actions.openAutomationSettings
        default:
            return actions.spotifyOpen
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

                SpotifyLogoView(size: 34)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SpotifyStatusIcon: View {
    let availability: SpotifyAvailability

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SpotifyLogoView(size: 38)

            if let badgeName {
                Image(systemName: badgeName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .frame(width: 18, height: 18)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
        }
    }

    private var badgeName: String? {
        switch availability {
        case .available:
            return "checkmark"
        case .permissionDenied:
            return "lock.fill"
        case .error:
            return "exclamationmark"
        default:
            return nil
        }
    }
}

private struct SeekableProgressBar: View {
    let progress: Double
    let theme: SpotifyTheme
    let onSeek: (Double) -> Void
    @State private var transientProgress: Double?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.14))

                Capsule()
                    .fill(theme.progressFill)
                    .frame(width: max(4, proxy.size.width * displayProgress))
                    .shadow(color: theme.progressFill.opacity(0.34), radius: 5, x: 0, y: 0)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        transientProgress = progress(for: value.location.x, width: proxy.size.width)
                    }
                    .onEnded { value in
                        let targetProgress = progress(for: value.location.x, width: proxy.size.width)
                        transientProgress = nil
                        onSeek(targetProgress)
                    }
            )
        }
        .frame(height: 5)
        .animation(.easeOut(duration: 0.24), value: progress)
        .animation(.easeOut(duration: 0.12), value: transientProgress)
        .help("Click or drag to seek")
        .panelDragExclusion()
    }

    private var displayProgress: Double {
        transientProgress ?? progress
    }

    private func progress(for xPosition: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return min(max(Double(xPosition / width), 0), 1)
    }
}

private struct VolumeControl: View {
    let volume: Double
    let theme: SpotifyTheme
    let onVolumePreview: (Double) -> Void
    let onVolumeCommit: (Double) -> Void
    @State private var draftVolume: Double?

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: volumeIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.58))
                .frame(width: 12)

            Slider(
                value: Binding(
                    get: { draftVolume ?? volume },
                    set: { newValue in
                        draftVolume = newValue
                        onVolumePreview(newValue)
                    }
                ),
                in: 0...100,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        let finalVolume = draftVolume ?? volume
                        draftVolume = nil
                        onVolumeCommit(finalVolume)
                    }
                }
            )
            .controlSize(.mini)
            .tint(theme.progressFill)
        }
        .frame(height: 14)
        .help("Volume")
        .panelDragExclusion()
    }

    private var volumeIcon: String {
        switch volume {
        case 0...1:
            return "speaker.slash.fill"
        case 1..<45:
            return "speaker.wave.1.fill"
        case 45..<75:
            return "speaker.wave.2.fill"
        default:
            return "speaker.wave.3.fill"
        }
    }
}

private struct HeartButton: View {
    let status: SpotifySavedTrackStatus
    let theme: SpotifyTheme
    let action: () -> Void
    @State private var isHovering = false
    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: status.isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 34, height: 24)

                if isPulsing {
                    Image(systemName: status.isSaved ? "checkmark.circle.fill" : "minus.circle.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: 5, y: -4)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(foregroundColor)
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .scaleEffect(isPulsing ? 1.16 : (isHovering ? 1.06 : 1))
        .opacity(status.isWorking ? 0.55 : 1)
        .disabled(status.isWorking)
        .animation(.easeInOut(duration: 0.13), value: isHovering)
        .animation(.spring(response: 0.22, dampingFraction: 0.62), value: isPulsing)
        .onHover { isHovering = $0 }
        .onChange(of: status.isSaved) { _, _ in
            pulse()
        }
        .help(status.helpText)
        .panelDragExclusion()
    }

    private var buttonBackground: Color {
        if status.isSaved {
            return Color(red: 0.12, green: 0.73, blue: 0.33).opacity(isHovering ? 0.28 : 0.20)
        }

        return isHovering ? theme.controlHoverBackground : theme.controlBackground
    }

    private var foregroundColor: Color {
        if status.isSaved {
            return Color(red: 0.36, green: 1.0, blue: 0.58)
        }

        return .white.opacity(isHovering ? 0.96 : 0.78)
    }

    private func pulse() {
        guard status == .saved || status == .notSaved else { return }

        isPulsing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            isPulsing = false
        }
    }
}

private struct SpotifyButton: View {
    let systemName: String
    let label: String
    var isPrimary = false
    var compact = false
    var isActive = false
    var isDisabled = false
    let theme: SpotifyTheme
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .bold))
                .frame(width: buttonWidth, height: buttonHeight)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foregroundColor)
        .background(buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: isPrimary ? 10 : 8, style: .continuous))
        .scaleEffect(isHovering ? 1.06 : 1)
        .opacity(isDisabled ? 0.55 : 1)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.13), value: isHovering)
        .animation(.easeInOut(duration: 0.13), value: isDisabled)
        .onHover { isHovering = $0 }
        .help(label)
        .panelDragExclusion()
    }

    private var iconSize: CGFloat {
        if isPrimary { return 13 }
        return compact ? 11 : 11
    }

    private var buttonWidth: CGFloat {
        if isPrimary { return 34 }
        return compact ? 34 : 28
    }

    private var buttonHeight: CGFloat {
        if isPrimary { return 32 }
        return compact ? 24 : 28
    }

    private var buttonBackground: Color {
        if isPrimary {
            return isHovering ? Color.white.opacity(0.92) : theme.primaryControlBackground
        }

        if isActive {
            return Color(red: 0.12, green: 0.73, blue: 0.33).opacity(isHovering ? 0.28 : 0.20)
        }

        return isHovering ? theme.controlHoverBackground : theme.controlBackground
    }

    private var foregroundColor: Color {
        if isPrimary {
            return theme.primaryControlForeground
        }

        if isActive {
            return Color(red: 0.36, green: 1.0, blue: 0.58)
        }

        return .white.opacity(isHovering ? 0.96 : 0.78)
    }
}

private struct EmptyStateButton: View {
    let title: String
    let systemName: String
    let theme: SpotifyTheme
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 11, weight: .bold))

                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(height: 32)
            .padding(.horizontal, 11)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.primaryControlForeground)
        .background(isHovering ? Color.white.opacity(0.92) : theme.primaryControlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .scaleEffect(isHovering ? 1.04 : 1)
        .animation(.easeInOut(duration: 0.13), value: isHovering)
        .onHover { isHovering = $0 }
        .help(title)
        .panelDragExclusion()
    }
}
