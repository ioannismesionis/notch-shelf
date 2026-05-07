import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings

    private let refreshOptions: [Double] = [1, 2, 5, 10]
    private let spotifyWebAPIClient = SpotifyWebAPIClient()

    @State private var launchAtLoginEnabled = LaunchAtLoginController.isEnabled
    @State private var launchAtLoginStatus = LaunchAtLoginController.statusText
    @State private var launchAtLoginError: String?
    @State private var availablePlaylists: [SpotifyPlaylist] = []
    @State private var playlistStatus = "Load playlists to pin up to five shortcuts."
    @State private var playlistError: String?
    @State private var isLoadingPlaylists = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Preferences")
                    .font(.system(size: 20, weight: .bold))

                panelSection

                Divider()

                spotifySection

                Divider()

                playlistsSection
            }
            .padding(24)
        }
        .frame(width: 500, height: 620, alignment: .topLeading)
        .onAppear(perform: refreshLaunchAtLoginState)
    }

    private var panelSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Panel")

            Toggle("Start pinned", isOn: $settings.startPinned)
            Toggle("Open at login", isOn: launchAtLoginBinding)

            Text("Launch at login: \(launchAtLoginStatus)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(launchAtLoginError == nil ? Color.secondary : Color.red)

            if let launchAtLoginError {
                Text(launchAtLoginError)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red)
            }

            Toggle("Option-Space shortcut", isOn: $settings.globalShortcutEnabled)

            Text("Shows NotchShelf expanded. Press again to hide or collapse it.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Picker("Panel background", selection: $settings.panelBackgroundMode) {
                ForEach(PanelBackgroundMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Button("Show first-run setup") {
                settings.firstRunSetupCompleted = false
            }
            .buttonStyle(.bordered)
        }
    }

    private var spotifySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Spotify")

            Picker("Refresh interval", selection: $settings.refreshInterval) {
                ForEach(refreshOptions, id: \.self) { option in
                    Text(refreshLabel(for: option)).tag(option)
                }
            }
            .pickerStyle(.segmented)

            TextField("Spotify Client ID", text: $settings.spotifyClientID)
                .textFieldStyle(.roundedBorder)

            Text("Redirect URI: notchshelf://spotify-auth")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Pinned Playlists")

                Spacer()

                Button(isLoadingPlaylists ? "Loading..." : "Load Playlists") {
                    loadPlaylists()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isLoadingPlaylists)
            }

            Text(playlistError ?? playlistStatus)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(playlistError == nil ? Color.secondary : Color.red)

            if settings.pinnedPlaylists.isEmpty {
                Text("No pinned playlists yet.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 6) {
                    ForEach(settings.pinnedPlaylists) { playlist in
                        PlaylistPinRow(
                            playlist: playlist,
                            isPinned: true,
                            isAtLimit: false,
                            action: { togglePinnedPlaylist(playlist) }
                        )
                    }
                }
            }

            if !availablePlaylists.isEmpty {
                Text("Available")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.top, 4)

                VStack(spacing: 6) {
                    ForEach(availablePlaylists) { playlist in
                        PlaylistPinRow(
                            playlist: playlist,
                            isPinned: settings.pinnedPlaylists.contains { $0.id == playlist.id },
                            isAtLimit: settings.pinnedPlaylists.count >= 5,
                            action: { togglePinnedPlaylist(playlist) }
                        )
                    }
                }
            }
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginEnabled },
            set: { enabled in
                updateLaunchAtLogin(enabled)
            }
        )
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil

        do {
            try LaunchAtLoginController.setEnabled(enabled)
        } catch {
            launchAtLoginError = error.localizedDescription
        }

        refreshLaunchAtLoginState()
    }

    private func refreshLaunchAtLoginState() {
        launchAtLoginEnabled = LaunchAtLoginController.isEnabled
        launchAtLoginStatus = LaunchAtLoginController.statusText
    }

    private func loadPlaylists() {
        playlistError = nil

        let clientID = settings.spotifyClientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clientID.isEmpty else {
            playlistError = "Add your Spotify Client ID first."
            return
        }

        isLoadingPlaylists = true
        playlistStatus = "Loading Spotify playlists..."

        let fetch = {
            spotifyWebAPIClient.playlists(clientID: clientID) { result in
                isLoadingPlaylists = false

                switch result {
                case .success(let playlists):
                    availablePlaylists = playlists
                    playlistStatus = playlists.isEmpty
                        ? "No playlists returned by Spotify."
                        : "Pin up to five playlists for the notch."
                case .failure(let error):
                    playlistError = Self.message(for: error)
                }
            }
        }

        if spotifyWebAPIClient.hasRequiredScopes() {
            fetch()
            return
        }

        spotifyWebAPIClient.authorize(clientID: clientID) { result in
            switch result {
            case .success:
                fetch()
            case .failure(let error):
                isLoadingPlaylists = false
                playlistError = Self.message(for: error)
            }
        }
    }

    private func togglePinnedPlaylist(_ playlist: SpotifyPlaylist) {
        if settings.pinnedPlaylists.contains(where: { $0.id == playlist.id }) {
            settings.pinnedPlaylists.removeAll { $0.id == playlist.id }
            return
        }

        guard settings.pinnedPlaylists.count < 5 else {
            playlistError = "You can pin up to five playlists."
            return
        }

        settings.pinnedPlaylists.append(playlist)
        playlistError = nil
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func refreshLabel(for seconds: Double) -> String {
        if seconds == 1 {
            return "1 sec"
        }

        return "\(Int(seconds)) sec"
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

private struct PlaylistPinRow: View {
    let playlist: SpotifyPlaylist
    let isPinned: Bool
    let isAtLimit: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note.list")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.secondary.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                Text(playlist.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(isPinned ? "Unpin" : "Pin") {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!isPinned && isAtLimit)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
