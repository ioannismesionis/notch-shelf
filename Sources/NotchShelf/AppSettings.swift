import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var startPinned: Bool {
        didSet { defaults.set(startPinned, forKey: Keys.startPinned) }
    }

    @Published var refreshInterval: Double {
        didSet { defaults.set(refreshInterval, forKey: Keys.refreshInterval) }
    }

    @Published var spotifyClientID: String {
        didSet { defaults.set(spotifyClientID, forKey: Keys.spotifyClientID) }
    }

    @Published var globalShortcutEnabled: Bool {
        didSet { defaults.set(globalShortcutEnabled, forKey: Keys.globalShortcutEnabled) }
    }

    @Published var firstRunSetupCompleted: Bool {
        didSet { defaults.set(firstRunSetupCompleted, forKey: Keys.firstRunSetupCompleted) }
    }

    @Published var pinnedPlaylists: [SpotifyPlaylist] {
        didSet { savePinnedPlaylists() }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.startPinned: false,
            Keys.refreshInterval: 2.0,
            Keys.spotifyClientID: "",
            Keys.globalShortcutEnabled: true,
            Keys.firstRunSetupCompleted: false
        ])

        startPinned = defaults.bool(forKey: Keys.startPinned)
        refreshInterval = defaults.double(forKey: Keys.refreshInterval)
        spotifyClientID = defaults.string(forKey: Keys.spotifyClientID) ?? ""
        globalShortcutEnabled = defaults.bool(forKey: Keys.globalShortcutEnabled)
        firstRunSetupCompleted = defaults.bool(forKey: Keys.firstRunSetupCompleted)
        pinnedPlaylists = Self.loadPinnedPlaylists(from: defaults)
    }

    private static func loadPinnedPlaylists(from defaults: UserDefaults) -> [SpotifyPlaylist] {
        guard let data = defaults.data(forKey: Keys.pinnedPlaylists),
              let playlists = try? JSONDecoder().decode([SpotifyPlaylist].self, from: data) else {
            return []
        }

        return playlists
    }

    private func savePinnedPlaylists() {
        guard let data = try? JSONEncoder().encode(pinnedPlaylists) else { return }
        defaults.set(data, forKey: Keys.pinnedPlaylists)
    }
}

private enum Keys {
    static let startPinned = "startPinned"
    static let refreshInterval = "refreshInterval"
    static let spotifyClientID = "spotifyClientID"
    static let globalShortcutEnabled = "globalShortcutEnabled"
    static let firstRunSetupCompleted = "firstRunSetupCompleted"
    static let pinnedPlaylists = "pinnedPlaylists"
}
