import SwiftUI

struct FirstRunSetupView: View {
    @ObservedObject var store: ShelfStore
    let actions: ShelfActions
    let theme: SpotifyTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 11) {
                SpotifyLogoView(size: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Set up NotchShelf")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Connect the Spotify pieces once, then keep the app out of your way.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Button(action: actions.completeFirstRunSetup) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 34, height: 30)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.primaryControlForeground)
                .background(theme.primaryControlBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .help("Finish setup")
            }

            VStack(spacing: 8) {
                SetupRow(
                    title: "Spotify app",
                    detail: store.isSpotifyAppInstalled ? "Installed" : "Install Spotify to read playback.",
                    state: store.isSpotifyAppInstalled ? .done : .attention,
                    buttonTitle: "Open",
                    buttonIcon: "arrow.up.forward.app",
                    theme: theme,
                    action: actions.spotifyOpen
                )

                SetupRow(
                    title: "Automation permission",
                    detail: automationDetail,
                    state: automationState,
                    buttonTitle: "Settings",
                    buttonIcon: "gearshape.fill",
                    theme: theme,
                    action: actions.openAutomationSettings
                )

                SetupRow(
                    title: "Spotify Client ID",
                    detail: store.hasSpotifyClientID ? "Configured" : "Paste your client ID in Preferences.",
                    state: store.hasSpotifyClientID ? .done : .attention,
                    buttonTitle: "Prefs",
                    buttonIcon: "slider.horizontal.3",
                    theme: theme,
                    action: actions.openPreferences
                )

                SetupRow(
                    title: "Spotify access",
                    detail: libraryDetail,
                    state: libraryState,
                    buttonTitle: "Connect",
                    buttonIcon: "heart.fill",
                    isDisabled: !store.hasSpotifyClientID || store.isSpotifyLibraryConnected,
                    theme: theme,
                    action: actions.spotifyAuthorizeLibrary
                )

                SetupRow(
                    title: "Launch at login",
                    detail: store.launchAtLoginStatusText,
                    state: LaunchAtLoginController.isEnabled ? .done : .optional,
                    buttonTitle: "Enable",
                    buttonIcon: "power",
                    isDisabled: LaunchAtLoginController.isEnabled,
                    theme: theme,
                    action: actions.enableLaunchAtLogin
                )
            }

            HStack {
                Text("You can reopen this from Preferences.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.46))

                Spacer()

                Button("Done") {
                    actions.completeFirstRunSetup()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(15)
        .background(theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var automationDetail: String {
        switch store.spotifyStatus.availability {
        case .available, .noTrack:
            return "Allowed"
        case .permissionDenied:
            return "Allow NotchShelf in Privacy & Security."
        case .notRunning:
            return "Open Spotify once to trigger the permission prompt."
        case .error(let message):
            return message.isEmpty ? "Could not verify permission." : message
        }
    }

    private var automationState: SetupRow.StepState {
        switch store.spotifyStatus.availability {
        case .available, .noTrack:
            return .done
        case .permissionDenied, .error:
            return .attention
        case .notRunning:
            return .optional
        }
    }

    private var libraryDetail: String {
        if store.isSpotifyLibraryConnected {
            return "Connected"
        }

        if !store.hasSpotifyClientID {
            return "Needs a Client ID first."
        }

        return "Connect Liked Songs and playlists."
    }

    private var libraryState: SetupRow.StepState {
        if store.isSpotifyLibraryConnected {
            return .done
        }

        return store.hasSpotifyClientID ? .optional : .attention
    }
}

private struct SetupRow: View {
    enum StepState {
        case done
        case optional
        case attention
    }

    let title: String
    let detail: String
    let state: StepState
    let buttonTitle: String
    let buttonIcon: String
    var isDisabled = false
    let theme: SpotifyTheme
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(iconForeground)
                .frame(width: 26, height: 26)
                .background(iconBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)

                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: action) {
                HStack(spacing: 5) {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 10, weight: .bold))

                    Text(buttonTitle)
                        .font(.system(size: 11, weight: .bold))
                }
                .frame(height: 26)
                .padding(.horizontal, 9)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(isDisabled ? 0.36 : 0.86))
            .background(isHovering && !isDisabled ? theme.controlHoverBackground : theme.controlBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .disabled(isDisabled)
            .onHover { isHovering = $0 }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private var iconName: String {
        switch state {
        case .done:
            return "checkmark"
        case .optional:
            return "circle"
        case .attention:
            return "exclamationmark"
        }
    }

    private var iconForeground: Color {
        switch state {
        case .done:
            return .black.opacity(0.86)
        case .optional:
            return .white.opacity(0.72)
        case .attention:
            return .black.opacity(0.84)
        }
    }

    private var iconBackground: Color {
        switch state {
        case .done:
            return Color(red: 0.36, green: 1.0, blue: 0.58)
        case .optional:
            return Color.white.opacity(0.12)
        case .attention:
            return Color(red: 1.0, green: 0.82, blue: 0.34)
        }
    }
}
